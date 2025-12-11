#!/usr/bin/env python3
"""
Generate Dart code for transcript_provider.dart from Whisper JSON outputs.
Combines small segments into larger meaningful chunks and generates chapters.
"""

import json
import os
import re
from pathlib import Path

# Mapping of transcript files to drop IDs
TRANSCRIPT_MAPPING = {
    "Rethinking Rockets Cost 65 Million Dollars.json": "drop_001",
    "Charlie Munger Power of Inversion Thinking.json": "drop_002",
    "Slaying AI Inefficiency.json": "drop_003",
    "AI Exponential Growth and Global Policy Race.json": "drop_004",
    "Art of Effective Questions.json": "drop_007",
    "How to Master Irreversible Life Decisions.json": "drop_009",
    "2024 AI Index Progress & Peril.json": "drop_010",
    "Risk Budgeting and Robust Institutional Finance.json": "drop_011",
}

# Chapter titles and approximate timestamps for each drop
CHAPTER_INFO = {
    "drop_001": {
        "title": "First Principles Thinking",
        "chapters": [
            {"title": "The $65M Challenge", "start": 0, "desc": "Why rockets cost what they do"},
            {"title": "Breaking Down First Principles", "start": 180, "desc": "Understanding the methodology"},
            {"title": "The SpaceX Approach", "start": 400, "desc": "How Elon Musk applied first principles"},
            {"title": "Applying to Your Life", "start": 600, "desc": "Using first principles in everyday decisions"},
            {"title": "Key Takeaways", "start": 750, "desc": "Summary and action items"},
        ]
    },
    "drop_002": {
        "title": "Inversion Mental Model",
        "chapters": [
            {"title": "The Munger Philosophy", "start": 0, "desc": "Charlie Munger's approach to thinking"},
            {"title": "Avoiding Stupidity", "start": 120, "desc": "Why avoiding failure beats seeking success"},
            {"title": "Inversion in Practice", "start": 280, "desc": "Real-world applications of inversion"},
            {"title": "Common Mistakes to Avoid", "start": 420, "desc": "What guarantees failure"},
            {"title": "Building Better Decisions", "start": 540, "desc": "Putting it all together"},
        ]
    },
    "drop_003": {
        "title": "Second-Order Thinking",
        "chapters": [
            {"title": "The Problem with AI Tools", "start": 0, "desc": "Why AI often fails us"},
            {"title": "Thinking Beyond First Effects", "start": 80, "desc": "Understanding cascading consequences"},
            {"title": "The Efficiency Paradox", "start": 180, "desc": "When optimization backfires"},
            {"title": "Strategic Implementation", "start": 260, "desc": "How to think ahead effectively"},
        ]
    },
    "drop_004": {
        "title": "AI Exponential Growth & Policy",
        "chapters": [
            {"title": "The Exponential Curve", "start": 0, "desc": "Understanding AI's growth trajectory"},
            {"title": "Global Competition", "start": 180, "desc": "The race between nations"},
            {"title": "Policy Responses", "start": 400, "desc": "How governments are reacting"},
            {"title": "Career Implications", "start": 580, "desc": "What this means for you"},
            {"title": "Looking Ahead", "start": 720, "desc": "Preparing for the future"},
        ]
    },
    "drop_007": {
        "title": "The Art of Asking Questions",
        "chapters": [
            {"title": "The Power of Questions", "start": 0, "desc": "Why questions matter more than answers"},
            {"title": "The Socratic Method", "start": 90, "desc": "Ancient wisdom for modern inquiry"},
            {"title": "Types of Powerful Questions", "start": 180, "desc": "Different questions for different purposes"},
            {"title": "Mastering the Art", "start": 280, "desc": "Practical techniques to improve"},
        ]
    },
    "drop_009": {
        "title": "Reversible vs Irreversible Decisions",
        "chapters": [
            {"title": "The Bezos Framework", "start": 0, "desc": "Type 1 vs Type 2 decisions"},
            {"title": "Identifying Decision Types", "start": 200, "desc": "How to categorize your choices"},
            {"title": "When to Move Fast", "start": 400, "desc": "Embracing reversible decisions"},
            {"title": "When to Slow Down", "start": 580, "desc": "Handling irreversible choices"},
            {"title": "Decision Hygiene", "start": 720, "desc": "Building better decision habits"},
        ]
    },
    "drop_010": {
        "title": "2024 AI Index: Progress & Peril",
        "chapters": [
            {"title": "Introduction: The State of AI", "start": 0, "desc": "Overview of Stanford's 2024 AI Index Report"},
            {"title": "Unprecedented Speed", "start": 67, "desc": "The explosive pace of AI development"},
            {"title": "Multimodal AI Breakthroughs", "start": 150, "desc": "New capabilities in vision, text, and audio"},
            {"title": "The Dark Side: Model Collapse", "start": 218, "desc": "Risks of AI training on AI-generated data"},
            {"title": "Safety & Bias Concerns", "start": 298, "desc": "AI safety vulnerabilities and cultural biases"},
            {"title": "Key Takeaways", "start": 390, "desc": "The dual nature of AI and our responsibility"},
        ]
    },
    "drop_011": {
        "title": "Risk Budgeting & Institutional Finance",
        "chapters": [
            {"title": "Introduction to Risk Budgeting", "start": 0, "desc": "What institutional investors know"},
            {"title": "Risk vs Return", "start": 200, "desc": "Reframing the investment equation"},
            {"title": "Portfolio Construction", "start": 400, "desc": "Building robust allocations"},
            {"title": "Behavioral Traps", "start": 620, "desc": "Psychology of market panics"},
            {"title": "Practical Applications", "start": 820, "desc": "Applying these principles"},
        ]
    },
}


def combine_segments(segments, target_duration=15):
    """Combine small segments into larger chunks of ~target_duration seconds."""
    combined = []
    current_text = []
    current_start = None
    current_end = 0
    
    for seg in segments:
        if current_start is None:
            current_start = seg['start']
        
        current_text.append(seg['text'].strip())
        current_end = seg['end']
        
        # Check if we should close this segment
        duration = current_end - current_start
        if duration >= target_duration or seg['text'].strip().endswith(('.', '?', '!')):
            if duration >= 8:  # Minimum 8 seconds per segment
                combined.append({
                    'start': current_start,
                    'end': current_end,
                    'text': ' '.join(current_text)
                })
                current_text = []
                current_start = None
    
    # Don't forget the last segment
    if current_text:
        combined.append({
            'start': current_start,
            'end': current_end,
            'text': ' '.join(current_text)
        })
    
    return combined


def escape_dart_string(s):
    """Escape a string for Dart single quotes."""
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("$", "\\$")


def generate_dart_transcript(drop_id, segments, chapters):
    """Generate Dart code for a single transcript."""
    lines = []
    lines.append(f"  // {CHAPTER_INFO[drop_id]['title']} - {drop_id}")
    lines.append(f"  '{drop_id}': Transcript(")
    lines.append("    chapters: const [")
    
    # Generate chapters
    for i, ch in enumerate(chapters):
        end_time = chapters[i + 1]['start'] if i + 1 < len(chapters) else segments[-1]['end']
        lines.append("      AudioChapter(")
        lines.append(f"        title: '{escape_dart_string(ch['title'])}',")
        lines.append(f"        description: '{escape_dart_string(ch['desc'])}',")
        lines.append(f"        startTime: {ch['start']},")
        lines.append(f"        endTime: {int(end_time)},")
        lines.append("      ),")
    
    lines.append("    ],")
    lines.append("    segments: const [")
    
    # Generate segments
    for i, seg in enumerate(segments):
        lines.append("      TranscriptSegment(")
        lines.append(f"        id: '{drop_id}_{i+1}',")
        lines.append(f"        text: '{escape_dart_string(seg['text'])}',")
        lines.append(f"        startTime: {seg['start']},")
        lines.append(f"        endTime: {seg['end']},")
        lines.append("      ),")
    
    lines.append("    ],")
    lines.append("  ),")
    
    return "\n".join(lines)


def main():
    transcripts_dir = Path(__file__).parent.parent / "transcripts"
    
    all_dart_code = []
    
    for filename, drop_id in TRANSCRIPT_MAPPING.items():
        filepath = transcripts_dir / filename
        if not filepath.exists():
            print(f"Warning: {filename} not found")
            continue
        
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        segments = data.get('segments', [])
        combined = combine_segments(segments)
        chapters = CHAPTER_INFO.get(drop_id, {}).get('chapters', [])
        
        dart_code = generate_dart_transcript(drop_id, combined, chapters)
        all_dart_code.append(dart_code)
        
        print(f"✅ {drop_id}: {len(combined)} segments, {len(chapters)} chapters")
    
    # Print the combined Dart code
    print("\n" + "=" * 60)
    print("DART CODE FOR transcript_provider.dart")
    print("=" * 60 + "\n")
    print("\n".join(all_dart_code))


if __name__ == "__main__":
    main()
