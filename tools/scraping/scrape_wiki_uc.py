"""
Скрипт для парсинга страниц wiki.gg с использованием undetected-chromedriver.
Специально для обхода Cloudflare.
"""

import os
import re
import time
from urllib.parse import unquote, urlparse
from bs4 import BeautifulSoup
import html2text
import undetected_chromedriver as uc

# Настройки
LINKS_FILE = "all_links_from_wiki.txt.txt"
OUTPUT_DIR = "wiki_pages"
DELAY_BETWEEN_REQUESTS = 2.0
MAX_RETRIES = 3

def sanitize_filename(name):
    name = unquote(name)
    invalid_chars = r'<>:"/\|?*'
    for char in invalid_chars:
        name = name.replace(char, '_')
    name = name.strip('. ')
    return name[:200]

def get_page_name_from_url(url):
    parsed = urlparse(url)
    path = parsed.path
    if '/wiki/' in path:
        page_name = path.split('/wiki/')[-1]
    else:
        page_name = path.split('/')[-1] or 'index'
    return sanitize_filename(page_name)

def parse_wiki_page(html_content, url):
    soup = BeautifulSoup(html_content, 'html.parser')
    
    title_elem = soup.find('h1', {'id': 'firstHeading'}) or soup.find('h1', class_='page-header__title')
    title = title_elem.get_text(strip=True) if title_elem else get_page_name_from_url(url)
    
    content_div = (
        soup.find('div', {'id': 'mw-content-text'}) or
        soup.find('div', class_='mw-parser-output')
    )
    
    if not content_div:
        return None
    
    for elem in content_div.find_all(['script', 'style', 'noscript', 'nav']):
        elem.decompose()
    
    for selector in ['.navbox', '.catlinks', '.mw-editsection', '.noprint', 
                     '.mbox', '.ambox', '.navigation-not-searchable',
                     '.toc', '#toc', '.wikitable.navbox', '.mw-jump-link',
                     '.printfooter', '.mw-indicators']:
        for elem in content_div.select(selector):
            elem.decompose()
    
    for img in content_div.find_all(['img', 'picture', 'figure']):
        img.decompose()
    
    h = html2text.HTML2Text()
    h.ignore_links = False
    h.ignore_images = True
    h.ignore_emphasis = False
    h.body_width = 0
    h.unicode_snob = True
    
    markdown_content = h.handle(str(content_div))
    markdown_content = re.sub(r'\n{3,}', '\n\n', markdown_content)
    markdown_content = markdown_content.strip()
    
    result = f"# {title}\n\n"
    result += f"> Источник: {url}\n\n"
    result += markdown_content
    
    return result

def is_cloudflare_page(html):
    return "Just a moment" in html or ("Cloudflare" in html[:3000] and "mw-content-text" not in html)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, OUTPUT_DIR)
    os.makedirs(output_path, exist_ok=True)
    
    links_path = os.path.join(script_dir, LINKS_FILE)
    
    with open(links_path, 'r', encoding='utf-8') as f:
        urls = [line.strip() for line in f if line.strip() and line.strip().startswith('http')]
    
    print(f"Найдено {len(urls)} ссылок для парсинга")
    print(f"Результаты: {output_path}")
    print("-" * 50)
    
    # Настройки Chrome
    options = uc.ChromeOptions()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1920,1080')
    
    driver = uc.Chrome(options=options, version_main=None)
    
    success_count = 0
    error_count = 0
    
    # Разогрев
    print("Разогрев браузера...")
    driver.get("https://thekingiswatching.wiki.gg/wiki/The_King_Is_Watching")
    time.sleep(10)
    print("Разогрев завершён")
    
    for i, url in enumerate(urls, 1):
        page_name = get_page_name_from_url(url)
        filename = f"{page_name}.md"
        filepath = os.path.join(output_path, filename)
        
        print(f"[{i}/{len(urls)}] {page_name}...", end=" ", flush=True)
        
        if os.path.exists(filepath):
            # Проверяем что файл содержит реальный контент
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            if len(content) > 200 and "Just a moment" not in content:
                print("уже есть")
                success_count += 1
                continue
        
        retry = 0
        page_ok = False
        
        while retry < MAX_RETRIES and not page_ok:
            try:
                driver.get(url)
                time.sleep(3)
                
                html = driver.page_source
                
                # Если Cloudflare - ждём
                wait_count = 0
                while is_cloudflare_page(html) and wait_count < 10:
                    time.sleep(2)
                    html = driver.page_source
                    wait_count += 1
                
                if is_cloudflare_page(html):
                    retry += 1
                    time.sleep(3)
                    continue
                
                markdown = parse_wiki_page(html, url)
                
                if not markdown or len(markdown) < 100:
                    retry += 1
                    time.sleep(2)
                    continue
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(markdown)
                
                print("OK")
                success_count += 1
                page_ok = True
                
            except Exception as e:
                retry += 1
                if retry >= MAX_RETRIES:
                    print(f"ОШИБКА: {str(e)[:40]}")
                    error_count += 1
                else:
                    time.sleep(3)
        
        if not page_ok and retry >= MAX_RETRIES:
            print("НЕУДАЧА")
            error_count += 1
        
        time.sleep(DELAY_BETWEEN_REQUESTS)
    
    driver.quit()
    
    print("-" * 50)
    print(f"Завершено! Успешно: {success_count}, Ошибок: {error_count}")

if __name__ == "__main__":
    main()
