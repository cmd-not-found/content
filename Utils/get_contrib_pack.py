#!/usr/bin/env python3
import argparse
import os
import shutil
import sys

import requests
from demisto_sdk.commands.common.tools import run_command, print_error, print_success


def main():
    parser = argparse.ArgumentParser(description='Deploy a pack from a contribution PR to a branch')
    parser.add_argument('-p', '--pr_number', help='Contrib PR number')
    parser.add_argument('-b', '--branch', help='The contrib branch')
    parser.add_argument('-u', '--user', help='The contrib repo')
    args = parser.parse_args()

    pr_number = args.pr_number
    user = args.user
    branch = args.branch
    page = 1
    pack_dir_name = ''
    while True:
        response = requests.get(f'https://api.github.com/repos/demisto/content/pulls/{pr_number}/files',
                                params={'page': str(page)})
        response.raise_for_status()
        files = response.json()
        if not files:
            break
        for pr_file in files:
            if pr_file['filename'].startswith('Packs/'):
                pack_dir_name = pr_file['filename'].split('/')[1]
                break
        if pack_dir_name:
            break
        page += 1

    if not pack_dir_name:
        print_error('Did not find a pack in the PR')
        sys.exit(1)

    pack_dir = f'Packs/{pack_dir_name}'
    print(f'Copy the changes from the contributor branch {user}/{branch} in the pack {pack_dir_name}')

    try:
        shutil.rmtree(pack_dir)
        commands = [
            f'git remote add {user} git@github.com:{user}/content.git',
            f'git fetch {user} {branch}'
            f'git checkout {user}/{branch} {pack_dir}'
        ]

        for command in commands:
            print(f'Running command {command}')
            run_command(command, is_silenced=False)
    except Exception as e:
        print_error(f'Failed to deploy contributed pack to base branch: {e}')
        sys.exit(1)

    print_success(f'Successfully updated the base branch with the contrib pack {pack_dir_name}')


if __name__ == "__main__":
    main()
