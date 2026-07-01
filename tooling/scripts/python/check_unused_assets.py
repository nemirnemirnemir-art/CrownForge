import os
import re

def main():
    project_root = os.getcwd()
    
    # Extensions we care about tracking usage for
    asset_extensions = {
        '.png', '.jpg', '.jpeg', '.svg',  # Images
        '.wav', '.ogg', '.mp3',           # Audio
        '.tscn', '.scn',                  # Scenes
        '.gd', '.cs',                     # Scripts
        '.tres', '.res',                  # Resources
        '.ttf', '.otf',                   # Fonts
        '.json', '.txt', '.md'            # Data/Text
    }
    
    # Extensions we scan for references inside
    source_extensions = {
        '.tscn', '.scn',
        '.gd', '.cs',
        '.tres', '.res',
        '.project', # project.godot
        '.import'   # .import files sometimes contain useful info
    }

    all_files = set()
    referenced_files = set()
    
    # Files to ignore
    ignore_dirs = {'.git', '.godot', '.import', 'addons'} # Addons often have their own internal structure
    
    print("Scanning project files...")
    
    for root, dirs, files in os.walk(project_root):
        # Filter directories in-place
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, project_root).replace('\\', '/')
            res_path = "res://" + rel_path
            
            # Record existence
            if ext in asset_extensions:
                all_files.add(res_path)
            
            # Scan content if it's a source file
            if ext in source_extensions or file == 'project.godot':
                try:
                    with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        # Regex for res:// paths
                        # Matches: res://path/to/file.ext
                        res_matches = re.findall(r'res://[^"\'\n\),<\s]+', content)
                        for match in res_matches:
                            # Clean up the match (sometimes trailing chars get caught)
                            clean_match = match.strip('",\'')
                            referenced_files.add(clean_match)
                            
                        # Also scan for just filenames (e.g. load("MyScene.tscn"))
                        # This is looser but helps catch relative loads or dynamic string construction
                        # We only look for filenames with extensions we care about
                        for asset_ext in asset_extensions:
                            # regex: look for any word ending in .ext
                            # This is computationally expensive, so let's try a simpler approach
                            # We'll just look for the filename of every known asset in the content
                            pass
                            
                except Exception as e:
                    print(f"Error reading {rel_path}: {e}")

    # Second pass: Check for filenames only (for dynamic loading or relative paths)
    # To optimize, we'll iterate through all_files and check if their basename exists in ANY source content?
    # That's O(N*M), too slow.
    # Instead, let's build a set of all "tokens" found in all source files.
    
    print("Building token set from source files...")
    all_source_tokens = set()
    for root, dirs, files in os.walk(project_root):
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in source_extensions or file == 'project.godot':
                 try:
                    with open(os.path.join(root, file), 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        # specific crude tokenization
                        # split by typical delimiters
                        tokens = re.split(r'["\'\/\s\(\)\,\;]+', content)
                        all_source_tokens.update(tokens)
                 except:
                     pass

    print("Analyzing usage...")
    unused_files = []
    
    for file_path in all_files:
        # If explicitly referenced by full path, it's used
        if file_path in referenced_files:
            continue
            
        # Check if basename appears in tokens (heuristic for dynamic/relative load)
        basename = os.path.basename(file_path)
        if basename in all_source_tokens:
            continue
            
        # Special case: Main Scene defined in project.godot (usually covered by referenced_files scan of project.godot)
        
        unused_files.append(file_path)

    unused_files.sort()
    
    print(f"\nPotential Unused Files ({len(unused_files)}):")
    for f in unused_files:
        print(f)

if __name__ == "__main__":
    main()
