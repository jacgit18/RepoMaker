#!/bin/bash

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install Git and try again."
    exit 1
fi

# Check if user.email is set in Git config, and if not, prompt for it
if [ -z "$(git config user.email)" ]; then
    read -p "Enter your Git user email: " user_email
    git config user.email "$user_email"
fi

# Check if user.name is set in Git config, and if not, prompt for it
if [ -z "$(git config user.name)" ]; then
    read -p "Enter your Git user name: " user_name
    git config user.name "$user_name"
fi

# Check if GitHub username is provided as a parameter
if [ -z "$1" ]; then
    echo "Please provide your GitHub username as a parameter."
    exit 1
fi
github_username="$1"

# Check if GitHub personal access token is set
if [ -z "$TOKEN" ]; then
    echo "GitHub personal access token is not set. Please set the GITHUB_TOKEN environment variable."
    exit 1
fi

# Set the GitHub personal access token for authentication
github_token="$TOKEN"

# Prompt for repository name
read -p "Enter the name for your new repository: " repo_name

# Specify the directory where you want to create the repository
read -p "Enter the directory path (press Enter for the current directory): " repo_directory

# If no directory is specified, use the current directory
if [ -z "$repo_directory" ]; then
    repo_directory="."
fi

# Combine directory and repository name to get the full path
repo_path="$repo_directory/$repo_name"

# Check if the directory already exists
if [ -d "$repo_path" ]; then
    echo "A directory with the same name already exists."
    exit 1
fi

# Create the repository
echo "Creating repository at: $repo_path"
mkdir "$repo_path"
cd "$repo_path"
git init

# Create a README and make initial commit
echo "# $repo_name" > README.md
git add README.md
git commit -m "Initial commit"

# Authenticate with GitHub using the personal access token
# Create the repository on GitHub
create_repo_response=$(curl -X POST \
    -H "Authorization: token $github_token" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user/repos" \
    -d '{
        "name": "'"$repo_name"'",
        "private": false,
        "auto_init": false
    }')

# Check if repository creation was successful
if [ "$(echo "$create_repo_response" | jq -r '.id')" == "null" ]; then
    echo "Repository creation failed. Please check your GitHub credentials."
    exit 1
fi

# Set the remote origin for the repository
git remote add origin "https://github.com/$github_username/$repo_name.git"

# Push to GitHub
echo "Pushing repository to GitHub..."
git push -u origin master

echo "New repository '$repo_name' created in '$repo_directory' and pushed to GitHub."
