#!/usr/bin/env python3
"""Resolves Google Chat space members to their email addresses.

This script lists all HUMAN members of a given space and resolves their
Gaia IDs to email addresses using the gcontacts tool.
"""

import argparse
import json
import os
import subprocess
import sys


def find_binary(name):
  """Finds the binary in common release paths or PATH."""
  candidates = [
      f"/google/bin/releases/gemini-agents-{name}/{name}",
      f"/google/bin/releases/gemini-agents/{name}",
      f"/google/bin/releases/{name}",
  ]
  for c in candidates:
    if os.path.exists(c):
      return c
  # Fallback to PATH
  try:
    return subprocess.check_output(["which", name]).decode().strip()
  except subprocess.CalledProcessError:
    return None


def main():
  parser = argparse.ArgumentParser(
      description="Resolve space members to emails"
  )
  group = parser.add_mutually_exclusive_group(required=True)
  group.add_argument("--space", help="Space ID (e.g., AAQAWHULDXA)")
  group.add_argument("--file", help="File containing Gaia IDs (one per line)")
  args = parser.parse_args()

  gchat_bin = find_binary("gchat")
  gcontacts_bin = find_binary("gcontacts")

  if not gchat_bin:
    print("Error: gchat binary not found", file=sys.stderr)
    sys.exit(1)
  if not gcontacts_bin:
    print("Error: gcontacts binary not found", file=sys.stderr)
    sys.exit(1)

  user_ids = []

  if args.space:
    # 1. List members
    try:
      cmd = [gchat_bin, "list-members", args.space, "--json"]
      output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode()
      members = json.loads(output)
      for member in members:
        if member.get("type") != "HUMAN":
          continue
        name = member.get("name", "")
        parts = name.split("/")
        if len(parts) >= 4:
          user_ids.append(parts[-1])
    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
      print(f"Error listing members: {e}", file=sys.stderr)
      sys.exit(1)
  else:
    # Read from file
    try:
      with open(args.file, "r") as f:
        for line in f:
          uid = line.strip()
          if uid:
            if uid.startswith("users/"):
              uid = uid.split("/")[-1]
            user_ids.append(uid)
    except OSError as e:
      print(f"Error reading file {args.file}: {e}", file=sys.stderr)
      sys.exit(1)

  emails = []
  for user_id in user_ids:
    # 2. Resolve email
    try:
      cmd = [gcontacts_bin, "get", user_id, "--json"]
      c_output = subprocess.check_output(
          cmd, stderr=subprocess.DEVNULL
      ).decode()
      c_data = json.loads(c_output)

      # Parse email
      person_response = c_data.get("personResponse", [])
      if not person_response:
        continue

      person = person_response[0].get("person", {})
      email_list = person.get("email", [])

      if email_list:
        # Prefer primary email if flagged, otherwise take first
        email_val = email_list[0].get("value")
        for e in email_list:
          if e.get("metadata", {}).get("primary"):
            email_val = e.get("value")
            break
        if email_val:
          emails.append(email_val)
    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
      print(f"Warning: failed to resolve {user_id}: {e}", file=sys.stderr)

  if emails:
    print(",".join(emails))
  else:
    print("No emails found", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
  main()
