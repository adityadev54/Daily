#!/usr/bin/env python3
"""
Spera Transcript & Chapter Generator
Uses OpenAI Whisper for transcription and generates chapter markers.

Usage:
  python3 scripts/transcribe.py <audio_or_video_url_or_file> [--model medium] [--output json]

Examples:
  python3 scripts/transcribe.py https://archive.org/download/rethinking-rockets/audio.m4a
  python3 scripts/transcribe.py ./my_audio.mp3 --model large
  python3 scripts/transcribe.py ./video.mp4 --output srt
"""

import argparse
import json
import os
import sys
import tempfile
import urllib.request
from pathlib import Path
from typing import Optional

try:
    import whisper
except ImportError:
    print("Error: whisper not installed. Run: pip3 install openai-whisper")
    sys.exit(1)


def download_file(url: str, output_dir: str) -> str:
    """Download a file from URL to temp directory."""
    filename = url.split("/")[-1]
    # URL decode the filename
    filename = urllib.request.unquote(filename)
    output_path = os.path.join(output_dir, filename)
    
    print(f"📥 Downloading: {filename}")
    urllib.request.urlretrieve(url, output_path)
    print(f"✅ Downloaded to: {output_path}")
    return output_path


def format_timestamp(seconds: float) -> str:
    """Convert seconds to HH:MM:SS format."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    
    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    return f"{minutes:02d}:{secs:02d}"


def format_srt_timestamp(seconds: float) -> str:
    """Convert seconds to SRT format HH:MM:SS,mmm."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"


def generate_chapters(segments: list, min_gap: float = 30.0) -> list:
    """
    Generate chapter markers from transcript segments.
    
    Uses natural pauses (gaps > min_gap seconds) and topic shifts
    to determine chapter boundaries.
    """
    if not segments:
        return []
    
    chapters = []
    current_chapter_start = 0
    current_chapter_text = []
    last_end = 0
    
    for i, segment in enumerate(segments):
        text = segment["text"].strip()
        start = segment["start"]
        end = segment["end"]
        
        # Detect chapter break: significant pause or change in topic
        gap = start - last_end if last_end > 0 else 0
        
        # Start new chapter on significant gaps or every ~2-3 minutes
        should_break = (
            gap > min_gap or  # Long pause
            (start - current_chapter_start > 120 and gap > 5)  # 2+ min chapter with pause
        )
        
        if should_break and current_chapter_text:
            # Save previous chapter
            chapter_title = generate_chapter_title(current_chapter_text)
            chapters.append({
                "start": current_chapter_start,
                "start_formatted": format_timestamp(current_chapter_start),
                "title": chapter_title,
                "text_preview": " ".join(current_chapter_text[:3])[:200]
            })
            current_chapter_start = start
            current_chapter_text = []
        
        current_chapter_text.append(text)
        last_end = end
    
    # Don't forget the last chapter
    if current_chapter_text:
        chapter_title = generate_chapter_title(current_chapter_text)
        chapters.append({
            "start": current_chapter_start,
            "start_formatted": format_timestamp(current_chapter_start),
            "title": chapter_title,
            "text_preview": " ".join(current_chapter_text[:3])[:200]
        })
    
    # Number the chapters
    for i, chapter in enumerate(chapters):
        chapter["number"] = i + 1
    
    return chapters


def generate_chapter_title(texts: list) -> str:
    """Generate a chapter title from the first few sentences."""
    # Take first sentence or first 50 chars
    combined = " ".join(texts[:2])
    
    # Find first sentence end
    for end_char in [". ", "? ", "! "]:
        idx = combined.find(end_char)
        if idx > 10 and idx < 100:
            return combined[:idx].strip()
    
    # Fallback: first 60 chars
    if len(combined) > 60:
        # Try to break at a word boundary
        truncated = combined[:60]
        last_space = truncated.rfind(" ")
        if last_space > 40:
            return truncated[:last_space] + "..."
        return truncated + "..."
    
    return combined.strip() or "Introduction"


def transcribe(
    file_path: str,
    model_name: str = "medium",
    language: Optional[str] = None
) -> dict:
    """
    Transcribe audio/video file using Whisper.
    
    Args:
        file_path: Path to audio/video file
        model_name: Whisper model (tiny, base, small, medium, large)
        language: Optional language code (e.g., 'en')
    
    Returns:
        Dict with transcript, segments, and generated chapters
    """
    print(f"🎤 Loading Whisper model: {model_name}")
    print("   (First run will download the model, ~1.5GB for medium)")
    model = whisper.load_model(model_name)
    
    print(f"📝 Transcribing: {file_path}")
    print("   This may take a few minutes...")
    
    result = model.transcribe(
        file_path,
        language=language,
        verbose=False,
        word_timestamps=True
    )
    
    # Generate chapters from segments
    chapters = generate_chapters(result["segments"])
    
    # Build full transcript text
    full_text = result["text"].strip()
    
    # Build timestamped transcript
    timestamped_segments = []
    for seg in result["segments"]:
        timestamped_segments.append({
            "start": seg["start"],
            "end": seg["end"],
            "start_formatted": format_timestamp(seg["start"]),
            "end_formatted": format_timestamp(seg["end"]),
            "text": seg["text"].strip()
        })
    
    return {
        "language": result.get("language", "en"),
        "duration_seconds": result["segments"][-1]["end"] if result["segments"] else 0,
        "duration_formatted": format_timestamp(result["segments"][-1]["end"] if result["segments"] else 0),
        "full_transcript": full_text,
        "segments": timestamped_segments,
        "chapters": chapters,
        "word_count": len(full_text.split())
    }


def output_json(result: dict, output_path: str):
    """Save result as JSON."""
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"📄 JSON saved: {output_path}")


def output_srt(result: dict, output_path: str):
    """Save transcript as SRT subtitle file."""
    with open(output_path, "w", encoding="utf-8") as f:
        for i, seg in enumerate(result["segments"], 1):
            f.write(f"{i}\n")
            f.write(f"{format_srt_timestamp(seg['start'])} --> {format_srt_timestamp(seg['end'])}\n")
            f.write(f"{seg['text']}\n\n")
    print(f"📄 SRT saved: {output_path}")


def output_txt(result: dict, output_path: str):
    """Save as plain text with timestamps."""
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("=== CHAPTERS ===\n\n")
        for ch in result["chapters"]:
            f.write(f"[{ch['start_formatted']}] {ch['title']}\n")
        
        f.write("\n\n=== FULL TRANSCRIPT ===\n\n")
        f.write(result["full_transcript"])
        
        f.write("\n\n\n=== TIMESTAMPED SEGMENTS ===\n\n")
        for seg in result["segments"]:
            f.write(f"[{seg['start_formatted']}] {seg['text']}\n")
    print(f"📄 TXT saved: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Transcribe audio/video and generate chapters using Whisper"
    )
    parser.add_argument(
        "input",
        help="URL or file path to audio/video"
    )
    parser.add_argument(
        "--model", "-m",
        default="medium",
        choices=["tiny", "base", "small", "medium", "large"],
        help="Whisper model size (default: medium)"
    )
    parser.add_argument(
        "--output", "-o",
        default="all",
        choices=["json", "srt", "txt", "all"],
        help="Output format (default: all)"
    )
    parser.add_argument(
        "--language", "-l",
        default=None,
        help="Language code (e.g., 'en'). Auto-detected if not specified."
    )
    parser.add_argument(
        "--output-dir", "-d",
        default="./transcripts",
        help="Output directory (default: ./transcripts)"
    )
    
    args = parser.parse_args()
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Handle URL or local file
    input_path = args.input
    temp_dir = None
    
    if input_path.startswith("http://") or input_path.startswith("https://"):
        temp_dir = tempfile.mkdtemp()
        input_path = download_file(args.input, temp_dir)
    
    if not os.path.exists(input_path):
        print(f"❌ Error: File not found: {input_path}")
        sys.exit(1)
    
    # Transcribe
    try:
        result = transcribe(input_path, args.model, args.language)
    except Exception as e:
        print(f"❌ Transcription error: {e}")
        sys.exit(1)
    
    # Generate output filename
    base_name = Path(input_path).stem
    
    # Print summary
    print("\n" + "="*50)
    print("✅ TRANSCRIPTION COMPLETE")
    print("="*50)
    print(f"📊 Duration: {result['duration_formatted']}")
    print(f"📝 Word count: {result['word_count']}")
    print(f"🔤 Language: {result['language']}")
    print(f"📑 Chapters: {len(result['chapters'])}")
    
    print("\n📑 CHAPTERS:")
    for ch in result["chapters"]:
        print(f"   [{ch['start_formatted']}] {ch['title']}")
    
    # Save outputs
    print("\n💾 SAVING FILES:")
    
    if args.output in ["json", "all"]:
        output_json(result, output_dir / f"{base_name}.json")
    
    if args.output in ["srt", "all"]:
        output_srt(result, output_dir / f"{base_name}.srt")
    
    if args.output in ["txt", "all"]:
        output_txt(result, output_dir / f"{base_name}.txt")
    
    # Cleanup temp files
    if temp_dir:
        import shutil
        shutil.rmtree(temp_dir)
    
    print("\n✨ Done!")


if __name__ == "__main__":
    main()
