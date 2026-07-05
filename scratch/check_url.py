import requests

url = "https://sertifikasibag.com/inventory_kapal/syntax_sql/diagnose_inventory_db.php"
try:
    response = requests.get(url, timeout=10)
    print("Status Code:", response.status_code)
    # Replace checkmarks/crosses to avoid charmap errors
    text = response.text.replace('✓', '[OK]').replace('✗', '[ERROR]')
    print(text)
except Exception as e:
    print("Error:", e)
