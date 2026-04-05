from fastapi import FastAPI
from pydantic import BaseModel
import requests
from newspaper import Article
from urllib.parse import urlparse, parse_qs
from transformers import pipeline

app = FastAPI()

print("Loading model facebook/bart-large-mnli... This might take a minute.")
classifier = pipeline("zero-shot-classification", model="facebook/bart-large-mnli")
print("Model loaded successfully!")

class AnalyzeRequest(BaseModel):
    url: str
    headline: str = ""

def unwrap_google_url(url: str) -> str:
    try:
        if "google.com/url" in url:
            parsed = urlparse(url)
            qs = parse_qs(parsed.query)
            if 'q' in qs:
                return qs['q'][0]
            if 'url' in qs:
                return qs['url'][0]
            response = requests.get(url, allow_redirects=True, timeout=5)
            return response.url
        elif "google.com/search" in url:
            parsed = urlparse(url)
            qs = parse_qs(parsed.query)
            if 'q' in qs:
                query = qs['q'][0]
                ddg_url = f"https://html.duckduckgo.com/html/?q={query}"
                headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
                r = requests.get(ddg_url, headers=headers, timeout=5)
                import re
                match = re.search(r'class="result__url" href="([^"]+)"', r.text)
                if match:
                    link = match.group(1)
                    if link.startswith("//"): link = "https:" + link
                    if "uddg=" in link:
                        uqs = parse_qs(urlparse(link).query)
                        if 'uddg' in uqs: return uqs['uddg'][0]
                    return link
        return url
    except Exception as e:
        return url

def get_publisher_name(url: str) -> str:
    try:
        domain = urlparse(url).netloc.replace("www.", "")
        if "." in domain:
            parts = domain.split(".")
            return parts[0].capitalize()
        return domain
    except:
        return "News Source"

@app.post("/analyze")
def analyze(req: AnalyzeRequest):
    true_url = unwrap_google_url(req.url)
    source_name = get_publisher_name(true_url)
    
    try:
        article = Article(true_url)
        article.download()
        article.parse()
        text = article.text
        
        if not text or len(text) < 50:
            text = req.headline
            
    except Exception as e:
        print(f"Scraping error: {e}")
        text = req.headline

    labels = ["left-wing", "right-wing", "center"]
    try:
        result = classifier(text, candidate_labels=labels)
        top_label = result['labels'][0]
        score = result['scores'][0]
        
        bias_rating = "Center"
        if top_label == "left-wing" and score > 0.4:
            bias_rating = "Left"
        elif top_label == "right-wing" and score > 0.4:
            bias_rating = "Right"
            
        explanation = f"BART deep neural-network classified as {top_label} ({score*100:.1f}% confidence)."
        
        return {
            "trueUrl": true_url,
            "sourceName": source_name,
            "biasRating": bias_rating,
            "biasExplanation": explanation
        }
    except Exception as e:
        print("Model error:", e)
        return {
            "trueUrl": true_url,
            "sourceName": source_name,
            "biasRating": "Center",
            "biasExplanation": "Error analyzing bias."
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5000)
