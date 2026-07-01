
import re

def main():
    with open('project.godot', 'r', encoding='utf-8') as f:
        content = f.read()
        
    regex = re.compile(r'res://[^"\'\n\),]+')
    matches = regex.findall(content)
    
    print(f"Found {len(matches)} matches in project.godot")
    for m in matches:
        print(m)

if __name__ == "__main__":
    main()
