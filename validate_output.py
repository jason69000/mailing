import json
import os
import re
import sys
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:  # pragma: no cover - compatibility fallback
    from PyPDF2 import PdfReader

try:
    from playwright.sync_api import sync_playwright
except ImportError:  # pragma: no cover - optional dependency
    sync_playwright = None

BASE = Path(__file__).resolve().parent
HTML_DIR = BASE / "output_html"
PDF_DIR = BASE / "output_pdf"
EXPECTED_PAGES = 2
EXPECTED_TITLE_PREFIX = "Fintech Invoice "
BROWSER_RESULTS = []
SCREENSHOT_DIR = BASE / "web" / "screenshots"


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def extract_header_text(html_text: str):
    match = re.search(r"<h1[^>]*>(.*?)</h1>", html_text, flags=re.IGNORECASE | re.DOTALL)
    if not match:
        return None
    text = re.sub(r"<[^>]+>", " ", match.group(1))
    return normalize_text(text)


def validate_browser_render(inv: str, html_path: Path, expected_header: str) -> bool:
    """Load the invoice in Chromium and reject visible or runtime render failures."""
    if sync_playwright is None:
        BROWSER_RESULTS.append({
            "invoice": inv,
            "render_ok": False,
            "response_ok": False,
            "header_ok": False,
            "page_not_blank": False,
            "console_errors": [],
            "console_warnings": [],
            "console_logs": [],
            "page_errors": [],
            "failed_requests": [],
            "screenshot": None,
            "error": "playwright not installed",
        })
        print("BROWSER_RENDER_OK", False)
        print("BROWSER_RENDER_REASON", "playwright not installed")
        return False

    console_errors = []
    console_warnings = []
    console_logs = []
    page_errors = []
    failed_requests = []
    browser = None
    page = None
    screenshot = None

    def capture_screenshot() -> str | None:
        if page is None:
            return None
        try:
            SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
            safe_invoice = re.sub(r"[^A-Za-z0-9._-]", "_", inv)
            relative_path = f"screenshots/{safe_invoice}.png"
            page.screenshot(path=str(BASE / "web" / relative_path), full_page=True)
            return relative_path
        except Exception as exc:  # pragma: no cover - best-effort evidence capture
            print("BROWSER_SCREENSHOT_ERROR", str(exc))
            return None

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(viewport={"width": 1440, "height": 1200})
            def capture_console(message):
                if message.type == "error":
                    console_errors.append(message.text)
                elif message.type == "warning":
                    console_warnings.append(message.text)
                else:
                    console_logs.append(f"{message.type}: {message.text}")

            page.on("console", capture_console)
            page.on("pageerror", lambda error: page_errors.append(str(error)))
            page.on("requestfailed", lambda request: failed_requests.append(
                f"{request.url}: {request.failure or 'request failed'}"))

            response = page.goto(html_path.resolve().as_uri(), wait_until="load")
            page.wait_for_load_state("domcontentloaded")

            header = page.locator("h1").filter(has_text=expected_header)
            header_ok = header.count() > 0 and header.first.is_visible()
            body_text = page.locator("body").inner_text().strip()
            body_box = page.locator("body").bounding_box()
            page_not_blank = bool(body_text) and body_box is not None and body_box["height"] > 0
            response_ok = response is not None and response.ok
            browser_ok = response_ok and header_ok and page_not_blank and not console_errors and not page_errors and not failed_requests
            if not browser_ok:
                screenshot = capture_screenshot()
            browser.close()
    except Exception as exc:  # pragma: no cover - runtime safety
        screenshot = capture_screenshot()
        if browser is not None:
            browser.close()
        BROWSER_RESULTS.append({
            "invoice": inv,
            "render_ok": False,
            "response_ok": False,
            "header_ok": False,
            "page_not_blank": False,
            "console_errors": console_errors,
            "console_warnings": console_warnings,
            "console_logs": console_logs,
            "page_errors": page_errors,
            "failed_requests": failed_requests,
            "screenshot": screenshot,
            "error": str(exc),
        })
        safe_error = str(exc).encode("utf-8", "replace").decode("utf-8")
        print("BROWSER_RENDER_OK", False)
        print("BROWSER_RENDER_REASON", safe_error)
        if screenshot:
            print("BROWSER_SCREENSHOT", screenshot)
        return False

    if console_errors:
        print("BROWSER_CONSOLE_ERRORS", " | ".join(console_errors))
    if console_warnings:
        print("BROWSER_CONSOLE_WARNINGS", " | ".join(console_warnings))
    if console_logs:
        print("BROWSER_CONSOLE_LOGS", " | ".join(console_logs))
    if page_errors:
        print("BROWSER_PAGE_ERRORS", " | ".join(page_errors))
    if failed_requests:
        print("BROWSER_REQUEST_FAILURES", " | ".join(failed_requests))

    BROWSER_RESULTS.append({
        "invoice": inv,
        "render_ok": browser_ok,
        "response_ok": response_ok,
        "header_ok": header_ok,
        "page_not_blank": page_not_blank,
        "console_errors": console_errors,
        "console_warnings": console_warnings,
        "console_logs": console_logs,
        "page_errors": page_errors,
        "failed_requests": failed_requests,
        "screenshot": screenshot,
        "error": None,
    })
    print("BROWSER_RESPONSE_OK", response_ok)
    print("BROWSER_HEADER_VISIBLE", header_ok)
    print("BROWSER_PAGE_NOT_BLANK", page_not_blank)
    print("BROWSER_RENDER_OK", browser_ok)
    if screenshot:
        print("BROWSER_SCREENSHOT", screenshot)
    return browser_ok


def validate_invoice(inv: str) -> bool:
    html_path = HTML_DIR / f"{inv}.html"
    pdf_path = PDF_DIR / f"{inv}.pdf"

    print(f"\nINVOICE {inv}")

    html_exists = html_path.exists()
    print("HTML_EXISTS", html_exists)
    if not html_exists:
        return False

    pdf_exists = pdf_path.exists()
    print("PDF_EXISTS", pdf_exists)
    if not pdf_exists:
        return False

    try:
        reader = PdfReader(str(pdf_path))
        pages = len(reader.pages)
        info = reader.metadata or {}
        title = info.get("/Title") or ""
        creator = info.get("/Creator") or ""
        producer = info.get("/Producer") or ""
    except Exception as exc:  # pragma: no cover - runtime safety
        print("PDF_READ_ERROR", exc)
        return False

    print("PDF_PAGES", pages)
    print("PDF_TITLE", title)
    print("PDF_CREATOR", creator)
    print("PDF_PRODUCER", producer)

    expected_title = f"{EXPECTED_TITLE_PREFIX}{inv}"
    title_ok = title == expected_title
    print("TITLE_OK", title_ok)
    print("EXPECTED_TITLE", expected_title)
    if not title_ok:
        return False

    page_count_ok = pages == EXPECTED_PAGES
    print("PAGE_COUNT_OK", page_count_ok)
    if not page_count_ok:
        return False

    creator_ok = "wkhtmltopdf" in (creator or "").lower()
    print("CREATOR_OK", creator_ok)
    if not creator_ok:
        return False

    html_text = html_path.read_text(encoding="utf-8")
    expected_header = f"Invoice {inv}"
    header_text = extract_header_text(html_text)
    print("BODY_HEAD_EXPECTED", expected_header)
    print("BODY_HEAD_PRESENT", expected_header in (header_text or ""))
    if expected_header not in (header_text or ""):
        return False

    return validate_browser_render(inv, html_path, expected_header)


def write_browser_report() -> None:
    report_path = BASE / "web" / "browser_runtime.json"
    report_path.parent.mkdir(exist_ok=True)
    report_path.write_text(json.dumps({"invoices": BROWSER_RESULTS}, indent=2), encoding="utf-8")


def main() -> int:
    invoices = sys.argv[1:]
    if not invoices:
        invoices = sorted(p.stem for p in HTML_DIR.glob("*.html") if p.is_file())

    if not invoices:
        print("No invoice files found to validate.")
        return 1

    all_ok = True
    for inv in invoices:
        ok = validate_invoice(inv)
        print("RESULT", inv, "OK" if ok else "FAIL")
        all_ok = all_ok and ok

    write_browser_report()

    if not all_ok:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
