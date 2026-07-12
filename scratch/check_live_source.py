import requests

base_url = "https://sertifikasibag.com/inventory_kapal/api"

# Cek file submit_adjustment.php yang live - verifikasi source yang tersimpan
# dengan cara cek response dari endpoint diagnostik
url_check = f"{base_url}/submit_adjustment.php"

# Pertama cek dengan method GET untuk lihat apakah file sudah terupdate
r = requests.get(url_check, timeout=5)
print("GET (bukan POST) - Status:", r.status_code)
print("Response:", r.text)
