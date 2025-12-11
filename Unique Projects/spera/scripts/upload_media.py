#!/usr/bin/env python3
"""
Supabase Media Uploader for Spera

Usage:
    python upload_media.py <file_path> [--type audio|video] [--id drop_xxx]

Example:
    python upload_media.py ~/Downloads/my-video.mp4 --type video --id drop_005
    python upload_media.py ~/Downloads/my-audio.m4a --type audio --id drop_006
"""

import os
import sys
import argparse
import mimetypes
from pathlib import Path

try:
    from supabase import create_client, Client
except ImportError:
    print("Installing supabase-py...")
    os.system("pip3 install supabase")
    from supabase import create_client, Client

# Your Supabase credentials (same as in app)
SUPABASE_URL = "https://hydbyhlktomnlthwtuzb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5ZGJ5aGxrdG9tbmx0aHd0dXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTc3MTMsImV4cCI6MjA4MDc3MzcxM30.RUg47fnA8yAovjjoy52pTbNa2Nkpr-fktWfLHggwTVc"

# For uploads, you need the service_role key (more permissions)
# Get this from Supabase Dashboard → Settings → API → service_role key
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

BUCKET_NAME = "media"

def get_mime_type(file_path: str) -> str:
    """Get MIME type for file."""
    mime_type, _ = mimetypes.guess_type(file_path)
    return mime_type or "application/octet-stream"

def upload_file(file_path: str, content_type: str = "video", drop_id: str = None) -> str:
    """Upload a file to Supabase Storage."""
    
    if not SUPABASE_SERVICE_KEY:
        print("\n❌ Error: SUPABASE_SERVICE_KEY environment variable not set!")
        print("\nTo get your service key:")
        print("1. Go to Supabase Dashboard → Settings → API")
        print("2. Copy the 'service_role' key (NOT the anon key)")
        print("3. Run: export SUPABASE_SERVICE_KEY='your-key-here'")
        print("4. Then run this script again")
        sys.exit(1)
    
    # Use service key for uploads
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    file_path = Path(file_path).expanduser()
    
    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        sys.exit(1)
    
    # Generate storage path
    file_name = file_path.name
    if drop_id:
        # Use drop_id as folder: media/drop_001/video.mp4
        storage_path = f"{drop_id}/{file_name}"
    else:
        storage_path = f"{content_type}/{file_name}"
    
    print(f"\n📤 Uploading: {file_path.name}")
    print(f"   Size: {file_path.stat().st_size / (1024*1024):.2f} MB")
    print(f"   Destination: {BUCKET_NAME}/{storage_path}")
    
    mime_type = get_mime_type(str(file_path))
    print(f"   MIME Type: {mime_type}")
    
    try:
        with open(file_path, "rb") as f:
            response = supabase.storage.from_(BUCKET_NAME).upload(
                path=storage_path,
                file=f,
                file_options={"content-type": mime_type}
            )
        
        # Get public URL
        public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(storage_path)
        
        print(f"\n✅ Upload successful!")
        print(f"\n📎 Public URL:")
        print(f"   {public_url}")
        
        print(f"\n📋 Use this in mock_data.dart:")
        print(f"   contentUrl: '{public_url}',")
        
        return public_url
        
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")
        
        if "Bucket not found" in str(e):
            print("\n💡 The 'media' bucket doesn't exist. Create it:")
            print("   1. Go to Supabase Dashboard → Storage")
            print("   2. Click 'New Bucket'")
            print("   3. Name it 'media' and make it PUBLIC")
        
        sys.exit(1)

def list_files():
    """List files in the media bucket."""
    if not SUPABASE_SERVICE_KEY:
        print("Set SUPABASE_SERVICE_KEY to list files")
        return
    
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    try:
        files = supabase.storage.from_(BUCKET_NAME).list()
        print(f"\n📁 Files in '{BUCKET_NAME}' bucket:")
        for f in files:
            print(f"   - {f['name']}")
    except Exception as e:
        print(f"❌ Error listing files: {e}")

def main():
    parser = argparse.ArgumentParser(description="Upload media to Supabase Storage")
    parser.add_argument("file", nargs="?", help="File path to upload")
    parser.add_argument("--type", "-t", choices=["audio", "video"], default="video",
                        help="Content type (audio or video)")
    parser.add_argument("--id", "-i", help="Drop ID (e.g., drop_005)")
    parser.add_argument("--list", "-l", action="store_true", help="List existing files")
    
    args = parser.parse_args()
    
    if args.list:
        list_files()
        return
    
    if not args.file:
        parser.print_help()
        print("\n📌 Examples:")
        print("   python upload_media.py ~/Downloads/video.mp4 --type video --id drop_005")
        print("   python upload_media.py ~/Downloads/audio.m4a --type audio --id drop_006")
        print("   python upload_media.py --list")
        return
    
    upload_file(args.file, args.type, args.id)

if __name__ == "__main__":
    main()
