et -e
echo "🎵 Suite de la génération (CSS + templates + tests + README)..."

# ============ style.css (écrasé proprement) ============
cat > app/static/css/style.css <<'CSS_EOF'
:root{--bg:#0f1117;--surface:#1a1d27;--surface-hover:#242836;--text:#e4e4e7;--text-muted:#8b8fa3;--primary:#6366f1;--primary-hover:#818cf8;--danger:#ef4444;--border:#2a2d3a;--radius:8px}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:var(--bg);color:var(--text);line-height:1.6}
.navbar{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;background:var(--surface);border-bottom:1px solid var(--border);flex-wrap:wrap}
.nav-brand{font-weight:700;font-size:1.2rem;color:var(--text);text-decoration:none}
.nav-links{display:flex;gap:1rem;flex-wrap:wrap}
.nav-links a{color:var(--text-muted);text-decoration:none;padding:.4rem .8rem;border-radius:var(--radius);transition:all .2s}
.nav-links a:hover{color:var(--text);background:var(--surface-hover)}
.nav-btn{background:var(--surface-hover)}
main{max-width:1400px;margin:0 auto;padding:2rem}
.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:1rem;margin:1.5rem 0}
.stat-card{background:var(--surface);padding:1.2rem;border-radius:var(--radius);text-align:center;border:1px solid var(--border)}
.stat-number{display:block;font-size:2rem;font-weight:700;color:var(--primary)}
.stat-label{color:var(--text-muted);font-size:.85rem}
.cd-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:1.2rem;margin-top:1.5rem}
.cd-card{background:var(--surface);border-radius:var(--radius);overflow:hidden;border:1px solid var(--border);transition:transform .2s,border-color .2s}
.cd-card:hover{transform:translateY(-2px);border-color:var(--primary)}
.cd-card img{width:100%;aspect-ratio:1;object-fit:cover}
.cd-placeholder{width:100%;aspect-ratio:1;display:flex;align-items:center;justify-content:center;font-size:3rem;background:var(--surface-hover)}
.cd-placeholder.large{font-size:6rem}
.cd-info{padding:.8rem}
.cd-info strong{display:block;font-size:.9rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.cd-info span{display:block;font-size:.85rem;color:var(--text-muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.cd-info small{color:var(--text-muted);font-size:.75rem}
.search-bar{margin-bottom:1rem}
.search-bar input{width:100%;padding:.8rem 1rem;border-radius:var(--radius);border:1px solid var(--border);background:var(--surface);color:var(--text);font-size:1rem}
.filters{display:flex;gap:.8rem;flex-wrap:wrap;margin-bottom:1rem}
.filters select{padding:.5rem .8rem;border-radius:var(--radius);border:1px solid var(--border);background:var(--surface);color:var(--text)}
.pagination{display:flex;align-items:center;justify-content:center;gap:1.5rem;margin-top:2rem}
.pagination a{color:var(--primary);text-decoration:none}
.detail-layout{display:grid;grid-template-columns:300px 1fr;gap:2rem;margin:1.5rem 0}
.detail-cover img{width:100%;border-radius:var(--radius)}
.info-table{width:100%;border-collapse:collapse;margin-top:1rem}
.info-table td{padding:.5rem 0;border-bottom:1px solid var(--border)}
.info-table td:first-child{color:var(--text-muted);width:120px}
.tracklist{margin-top:2rem}
.tracklist table{width:100%;border-collapse:collapse}
.tracklist th{text-align:left;padding:.5rem;border-bottom:1px solid var(--border);color:var(--text-muted)}
.tracklist td{padding:.4rem .5rem;border-bottom:1px solid var(--border)}
.back-link{color:var(--text-muted);text-decoration:none}
.back-link:hover{color:var(--text)}
.tags{display:flex;gap:.4rem;flex-wrap:wrap;margin-top:1rem}
.tag{background:var(--primary);color:#fff;padding:.2rem .6rem;border-radius:99px;font-size:.75rem}
.btn{padding:.6rem 1.2rem;border-radius:var(--radius);border:none;cursor:pointer;font-size:.9rem;text-decoration:none;display:inline-block}
.btn-primary{background:var(--primary);color:#fff}
.btn-primary:hover{background:var(--primary-hover)}
.btn-secondary{background:var(--surface-hover);color:var(--text);border:1px solid var(--border)}
.btn-danger{background:var(--danger);color:#fff}
.detail-actions{display:flex;gap:.8rem;margin-top:2rem}
.form-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1rem;margin-bottom:1rem}
.form-grid label,.import-form label{display:flex;flex-direction:column;gap:.3rem;font-size:.85rem;color:var(--text-muted)}
input,select,textarea{padding:.6rem;border-radius:var(--radius);border:1px solid var(--border);background:var(--surface);color:var(--text);font-size:.9rem}
textarea{width:100%}
.login-page{display:flex;align-items:center;justify-content:center;min-height:100vh}
.login-box{background:var(--surface);padding:2.5rem;border-radius:var(--radius);border:1px solid var(--border);width:100%;max-width:350px;text-align:center}
.login-box input{width:100%;margin:1rem 0}
.login-box button{width:100%}
.toast{position:fixed;bottom:2rem;right:2rem;background:var(--primary);color:#fff;padding:.8rem 1.5rem;border-radius:var(--radius);z-index:1000}
.hidden{display:none}
.progress-bar{width:100%;height:8px;background:var(--surface-hover);border-radius:4px;overflow:hidden;margin:1rem 0}
#progress-fill{height:100%;background:var(--primary);width:0%;transition:width .3s}
.empty-state{color:var(--text-muted);text-align:center;padding:3rem}
.error{color:var(--danger)}
hr{border:none;border-top:1px solid var(--border);margin:2rem 0}
.ean-form{display:flex;gap:.5rem;margin:1rem 0}
.ean-form input{flex:1}
.lookup-card{background:var(--surface);padding:1.5rem;border-radius:var(--radius);border:1px solid var(--border);margin-top:1rem}
.tracklist-preview{list-style:none;margin:1rem 0;color:var(--text-muted);font-size:.9rem}
@media(max-width:768px){.detail-layout{grid-template-columns:1fr}.navbar{padding:.8rem 1rem}main{padding:1rem}}
CSS_EOF

# ============ templates/base.html ============
cat > app/templates/base.html <<'BASE_EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{% block title %}CD Manager{% endblock %}</title>
<script src="https://unpkg.com/htmx.org@1.9.12"></script>
<link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
<nav class="navbar">
<a href="/" class="nav-brand">🎵 CD Manager</a>
<div class="nav-links">
<a href="/collection" hx-get="/collection" hx-target="#main-content" hx-push-url="true">Collection</a>
<a href="/wantlist" hx-get="/wantlist" hx-target="#main-content" hx-push-url="true">Envies</a>
<a href="/add" hx-get="/add" hx-target="#main-content" hx-push-url="true">Ajouter</a>
<a href="/scan">Scanner</a>
<a href="/import/discogs" hx-get="/import/discogs" hx-target="#main-content" hx-push-url="true">Import Discogs</a>
<a href="/export/csv" class="nav-btn">Export CSV</a>
<a href="/export/pdf" class="nav-btn">Export PDF</a>
<a href="/logout" class="nav-btn">Déconnexion</a>
</div>
</nav>
<main id="main-content">{% block content %}{% endblock %}</main>
<div id="toast" class="toast hidden"></div>
<script>
document.body.addEventListener('htmx:afterSwap',function(e){const t=document.getElementById('toast');if(e.detail.target.dataset.toast){t.textContent=e.detail.target.dataset.toast;t.classList.remove('hidden');setTimeout(()=>t.classList.add('hidden'),3000);}});
document.body.addEventListener('htmx:confirm',function(e){if(e.detail.question){e.detail.issueRequest(window.confirm(e.detail.question));}});
</script>
</body>
</html>
BASE_EOF

# ============ templates/login.html ============
cat > app/templates/login.html <<'LOGIN_EOF'
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Connexion - CD Manager</title><link rel="stylesheet" href="/static/css/style.css"></head>
<body class="login-page">
<div class="login-box"><h1>🎵 CD Manager</h1>
{% if error %}<p class="error">{{ error }}</p>{% endif %}
<form method="POST" action="/login">
<input type="password" name="password" placeholder="Mot de passe" autofocus required>
<button type="submit" class="btn btn-primary">Connexion</button></form></div>
</body></html>
LOGIN_EOF

# ============ templates/dashboard.html ============
cat > app/templates/dashboard.html <<'DASH_EOF'
{% extends "base.html" %}
{% block title %}Dashboard - CD Manager{% endblock %}
{% block content %}
<div class="dashboard"><h1>Ma Collection</h1>
<div class="stats-grid">
<div class="stat-card"><span class="stat-number">{{ total_count }}</span><span class="stat-label">Supports</span></div>
<div class="stat-card"><span class="stat-number">{{ format_counts.get("CD", 0) }}</span><span class="stat-label">CDs</span></div>
<div class="stat-card"><span class="stat-number">{{ format_counts.get("Vinyle", 0) }}</span><span class="stat-label">Vinyles</span></div>
<div class="stat-card"><span class="stat-number">{{ format_counts.get("Cassette", 0) }}</span><span class="stat-label">K7</span></div>
<div class="stat-card"><span class="stat-number">{{ format_counts.get("MiniDisc", 0) }}</span><span class="stat-label">MiniDiscs</span></div>
<div class="stat-card"><span class="stat-number">{{ wantlist_count }}</span><span class="stat-label">Envies</span></div>
</div>
<h2>Derniers ajoutés</h2>
<div class="cd-grid">
{% for cd in recent_cds %}
<div class="cd-card" hx-get="/cd/{{ cd.id }}" hx-target="#main-content" hx-push-url="true" style="cursor:pointer">
{% if cd.cover_image_path %}<img src="/{{ cd.cover_image_path }}" alt="{{ cd.title }}" loading="lazy">{% else %}<div class="cd-placeholder">🎵</div>{% endif %}
<div class="cd-info"><strong>{{ cd.artist }}</strong><span>{{ cd.title }}</span><small>{{ cd.year or "?" }} · {{ cd.format or "?" }}</small></div>
</div>
{% endfor %}
</div></div>
{% endblock %}
DASH_EOF

# ============ templates/collection.html ============
cat > app/templates/collection.html <<'COLL_EOF'
{% extends "base.html" %}
{% block title %}Collection - CD Manager{% endblock %}
{% block content %}
<div class="collection-page">
<div class="search-bar"><input type="text" name="q" placeholder="Rechercher artiste, titre, label..." hx-get="/collection" hx-trigger="keyup changed delay:300ms" hx-target="#collection-results" hx-push-url="true" value="{{ query or '' }}"></div>
<div class="filters">
<select name="format" hx-get="/collection" hx-trigger="change" hx-target="#collection-results" hx-push-url="true">
<option value="">Tous formats</option>
<option value="CD" {% if format_filter=='CD' %}selected{% endif %}>CD</option>
<option value="Vinyle" {% if format_filter=='Vinyle' %}selected{% endif %}>Vinyle</option>
<option value="Cassette" {% if format_filter=='Cassette' %}selected{% endif %}>K7</option>
<option value="MiniDisc" {% if format_filter=='MiniDisc' %}selected{% endif %}>MiniDisc</option>
</select>
<select name="genre" hx-get="/collection" hx-trigger="change" hx-target="#collection-results" hx-push-url="true">
<option value="">Tous genres</option>
{% for g in genres %}<option value="{{ g }}" {% if genre_filter==g %}selected{% endif %}>{{ g }}</option>{% endfor %}
</select>
<select name="sort" hx-get="/collection" hx-trigger="change" hx-target="#collection-results" hx-push-url="true">
<option value="date_desc" {% if sort=='date_desc' %}selected{% endif %}>Plus récents</option>
<option value="artist_asc" {% if sort=='artist_asc' %}selected{% endif %}>Artiste A-Z</option>
<option value="year_desc" {% if sort=='year_desc' %}selected{% endif %}>Année ↓</option>
<option value="year_asc" {% if sort=='year_asc' %}selected{% endif %}>Année ↑</option>
</select>
</div>
<div id="collection-results">{% include "partials/collection_grid.html" %}</div>
</div>
{% endblock %}
COLL_EOF

# ============ templates/partials/collection_grid.html ============
cat > app/templates/partials/collection_grid.html <<'GRID_EOF'
<div class="cd-grid">
{% for cd in cds %}
<div class="cd-card" hx-get="/cd/{{ cd.id }}" hx-target="#main-content" hx-push-url="true" style="cursor:pointer">
{% if cd.cover_image_path %}<img src="/{{ cd.cover_image_path }}" alt="{{ cd.title }}" loading="lazy">{% else %}<div class="cd-placeholder">🎵</div>{% endif %}
<div class="cd-info"><strong>{{ cd.artist }}</strong><span>{{ cd.title }}</span><small>{{ cd.year or "?" }} · {{ cd.format or "?" }}</small></div>
</div>
{% else %}<p class="empty-state">Aucun résultat.</p>{% endfor %}
</div>
{% if total_pages > 1 %}
<div class="pagination">
{% if page > 1 %}<a hx-get="/collection?page={{ page-1 }}&q={{ query }}&format={{ format_filter }}&genre={{ genre_filter }}&sort={{ sort }}" hx-target="#collection-results" hx-push-url="true">← Précédent</a>{% endif %}
<span>Page {{ page }} / {{ total_pages }}</span>
{% if page < total_pages %}<a hx-get="/collection?page={{ page+1 }}&q={{ query }}&format={{ format_filter }}&genre={{ genre_filter }}&sort={{ sort }}" hx-target="#collection-results" hx-push-url="true">Suivant →</a>{% endif %}
</div>
{% endif %}
GRID_EOF

# ============ templates/cd_detail.html ============
cat > app/templates/cd_detail.html <<'DETAIL_EOF'
{% extends "base.html" %}
{% block title %}{{ cd.artist }} - {{ cd.title }}{% endblock %}
{% block content %}
<div class="cd-detail">
<a href="/collection" class="back-link">← Retour</a>
<div class="detail-layout">
<div class="detail-cover">{% if cd.cover_image_path %}<img src="/{{ cd.cover_image_path }}" alt="{{ cd.title }}">{% else %}<div class="cd-placeholder large">🎵</div>{% endif %}</div>
<div class="detail-info"><h1>{{ cd.title }}</h1><h2>{{ cd.artist }}</h2>
<table class="info-table">
<tr><td>Label</td><td>{{ cd.label or "—" }}</td></tr>
<tr><td>Cat#</td><td>{{ cd.catalog_number or "—" }}</td></tr>
<tr><td>Année</td><td>{{ cd.year or "—" }}</td></tr>
<tr><td>Format</td><td>{{ cd.format or "—" }}</td></tr>
<tr><td>Genre</td><td>{{ cd.genre or "—" }}</td></tr>
<tr><td>Style</td><td>{{ cd.style or "—" }}</td></tr>
<tr><td>Condition</td><td>{{ cd.condition or "—" }}</td></tr>
<tr><td>EAN</td><td>{{ cd.ean or "—" }}</td></tr>
<tr><td>Prix</td><td>{{ "%.2f"|format(cd.price_paid) if cd.price_paid else "—" }} {{ cd.currency }}</td></tr>
{% if cd.discogs_url %}<tr><td>Discogs</td><td><a href="{{ cd.discogs_url }}" target="_blank">Voir</a></td></tr>{% endif %}
</table>
{% if cd.notes %}<div class="notes"><h3>Notes</h3><p>{{ cd.notes }}</p></div>{% endif %}
{% if cd.tags %}<div class="tags">{% for tag in cd.tags %}<span class="tag">{{ tag.name }}</span>{% endfor %}</div>{% endif %}
</div></div>
{% if cd.tracks %}<div class="tracklist"><h3>Tracklist</h3>
<table><thead><tr><th>#</th><th>Titre</th><th>Durée</th></tr></thead><tbody>
{% for track in cd.tracks %}<tr><td>{{ track.position }}</td><td>{{ track.title }}</td><td>{{ track.duration or "" }}</td></tr>{% endfor %}
</tbody></table></div>{% endif %}
<div class="detail-actions">
<button hx-post="/cd/{{ cd.id }}/toggle-wantlist" hx-target="#main-content" hx-push-url="true" class="btn btn-secondary">{% if cd.in_wantlist %}← Collection{% else %}→ Envies{% endif %}</button>
<a href="/cd/{{ cd.id }}/edit" class="btn btn-secondary">Modifier</a>
<button hx-delete="/cd/{{ cd.id }}" hx-confirm="Supprimer ce support ?" hx-target="#main-content" hx-push-url="true" class="btn btn-danger">Supprimer</button>
</div></div>
{% endblock %}
DETAIL_EOF

# ============ templates/edit_cd.html ============
cat > app/templates/edit_cd.html <<'EDIT_EOF'
{% extends "base.html" %}
{% block title %}Modifier - {{ cd.title }}{% endblock %}
{% block content %}
<div class="add-page"><a href="/cd/{{ cd.id }}" class="back-link">← Retour</a><h1>Modifier</h1>
<form hx-put="/cd/{{ cd.id }}" hx-target="#main-content" hx-push-url="true" class="cd-form">
<div class="form-grid">
<label>Artiste *<input type="text" name="artist" value="{{ cd.artist }}" required></label>
<label>Titre *<input type="text" name="title" value="{{ cd.title }}" required></label>
<label>Label<input type="text" name="label" value="{{ cd.label or '' }}"></label>
<label>Cat#<input type="text" name="catalog_number" value="{{ cd.catalog_number or '' }}"></label>
<label>Année<input type="number" name="year" value="{{ cd.year or '' }}"></label>
<label>Format<select name="format">{% for f in ['CD','Vinyle','Cassette','MiniDisc','DVD','Autre'] %}<option value="{{ f }}" {% if cd.format==f %}selected{% endif %}>{{ f }}</option>{% endfor %}</select></label>
<label>Genre<input type="text" name="genre" value="{{ cd.genre or '' }}"></label>
<label>Style<input type="text" name="style" value="{{ cd.style or '' }}"></label>
<label>Condition<input type="text" name="condition" value="{{ cd.condition or '' }}"></label>
<label>EAN<input type="text" name="ean" value="{{ cd.ean or '' }}"></label>
<label>Prix<input type="number" name="price_paid" step="0.01" value="{{ cd.price_paid or '' }}"></label>
</div>
<label>Notes<textarea name="notes" rows="3">{{ cd.notes or '' }}</textarea></label>
<button type="submit" class="btn btn-primary">Enregistrer</button>
</form></div>
{% endblock %}
EDIT_EOF

# ============ templates/add_cd.html ============
cat > app/templates/add_cd.html <<'ADD_EOF'
{% extends "base.html" %}
{% block title %}Ajouter un support{% endblock %}
{% block content %}
<div class="add-page"><h1>Ajouter un support</h1>
<div class="lookup-section"><h2>Recherche rapide par EAN</h2>
<div class="ean-form"><input type="text" id="ean-input" placeholder="Scanner ou taper le code-barres..." autofocus {% if ean %}value="{{ ean }}"{% endif %}>
<button onclick="lookupEan()" class="btn btn-primary">Rechercher</button>
<a href="/scan" class="btn btn-secondary">📷 Scanner</a></div>
<div id="lookup-results"></div></div>
<hr>
<div class="manual-section"><h2>Saisie manuelle</h2>
<form hx-post="/cd" hx-target="#main-content" hx-push-url="true" class="cd-form">
<div class="form-grid">
<label>Artiste *<input type="text" name="artist" required></label>
<label>Titre *<input type="text" name="title" required></label>
<label>Label<input type="text" name="label"></label>
<label>Cat#<input type="text" name="catalog_number"></label>
<label>Année<input type="number" name="year" min="1900" max="2030"></label>
<label>Format<select name="format"><option value="CD">CD</option><option value="Vinyle">Vinyle</option><option value="Cassette">K7</option><option value="MiniDisc">MiniDisc</option><option value="DVD">DVD</option><option value="Autre">Autre</option></select></label>
<label>Genre<input type="text" name="genre"></label>
<label>Style<input type="text" name="style"></label>
<label>Condition<select name="condition"><option value="">—</option><option value="M">M</option><option value="NM">NM</option><option value="VG+">VG+</option><option value="VG">VG</option><option value="G">G</option><option value="P">Poor</option></select></label>
<label>EAN<input type="text" name="ean"></label>
<label>Prix<input type="number" name="price_paid" step="0.01" min="0"></label>
<label>Currency<select name="currency"><option value="EUR">EUR</option><option value="CHF">CHF</option><option value="GBP">GBP</option><option value="USD">USD</option></select></label>
</div>
<label>Notes<textarea name="notes" rows="3"></textarea></label>
<button type="submit" class="btn btn-primary">Ajouter</button>
</form></div></div>
<script>
async function lookupEan(){const ean=document.getElementById('ean-input').value.trim();if(!ean)return;const res=await fetch(`/lookup/ean/${ean}`);const data=await res.json();const c=document.getElementById('lookup-results');if(data.error){c.innerHTML=`<p class="error">${data.error}</p>`;return;}c.innerHTML=`<div class="lookup-card"><h3>${data.artist} — ${data.title}</h3><p>Source: ${data.source} | ${data.label||''} | ${data.year||''}</p><ul class="tracklist-preview">${data.tracks.slice(0,5).map(t=>`<li>${t.position}. ${t.title} ${t.duration}</li>`).join('')}${data.tracks.length>5?`<li>... et ${data.tracks.length-5} autres</li>`:''}</ul><button class="btn btn-primary" onclick="confirmAdd('${ean}')">Ajouter à ma collection</button></div>`;}
async function confirmAdd(ean){const res=await fetch(`/cd/add-from-lookup/${ean}`,{method:'POST'});const html=await res.text();document.getElementById('main-content').innerHTML=html;}
</script>
{% endblock %}
ADD_EOF

# ============ templates/scan.html ============
cat > app/templates/scan.html <<'SCAN_EOF'
{% extends "base.html" %}
{% block title %}Scanner un code-barres{% endblock %}
{% block content %}
<div class="scan-page"><h1>📷 Scanner un code-barres</h1>
<p>Ouvre cette page depuis ton téléphone (même réseau que le NAS) pour utiliser la caméra.</p>
<div id="reader" style="max-width:500px;margin:0 auto;"></div>
<div id="scan-result" class="hidden"><p>Code détecté : <strong id="scan-code"></strong></p><a id="scan-link" class="btn btn-primary">Rechercher</a></div>
</div>
<script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
<script>
const scanner=new Html5Qrcode("reader");
scanner.start({facingMode:"environment"},{fps:10,qrbox:{width:300,height:150}},(t)=>{scanner.stop();document.getElementById('scan-code').textContent=t;document.getElementById('scan-link').href=`/add?ean=${t}`;document.getElementById('scan-result').classList.remove('hidden');},()=>{}).catch(()=>{document.getElementById('reader').innerHTML=`<p class="error">Impossible d'accéder à la caméra. Vérifie que tu es en HTTPS ou sur localhost.</p>`;});
</script>
{% endblock %}
SCAN_EOF

# ============ templates/wantlist.html ============
cat > app/templates/wantlist.html <<'WL_EOF'
{% extends "base.html" %}
{% block title %}Envies - CD Manager{% endblock %}
{% block content %}
<div class="collection-page"><h1>Ma Wantlist</h1>
<div class="cd-grid">
{% for cd in cds %}
<div class="cd-card" hx-get="/cd/{{ cd.id }}" hx-target="#main-content" hx-push-url="true" style="cursor:pointer">
{% if cd.cover_image_path %}<img src="/{{ cd.cover_image_path }}" alt="{{ cd.title }}" loading="lazy">{% else %}<div class="cd-placeholder">🎵</div>{% endif %}
<div class="cd-info"><strong>{{ cd.artist }}</strong><span>{{ cd.title }}</span><small>{{ cd.year or "?" }} · {{ cd.format or "?" }}</small></div>
</div>
{% else %}<p class="empty-state">Ta wantlist est vide.</p>{% endfor %}
</div></div>
{% endblock %}
WL_EOF

# ============ templates/import_discogs.html ============
cat > app/templates/import_discogs.html <<'IMP_EOF'
{% extends "base.html" %}
{% block title %}Import Discogs{% endblock %}
{% block content %}
<div class="import-page"><h1>Importer depuis Discogs</h1>
<p>Cette opération peut prendre plusieurs minutes avec 1000+ références (rate limiting Discogs).</p>
<div class="import-form"><label>Username Discogs<input type="text" id="discogs-username" placeholder="ton_username"></label>
<button class="btn btn-primary" onclick="startImport()">Lancer l'import</button></div>
<div id="import-progress" class="hidden"><div class="progress-bar"><div id="progress-fill"></div></div><p id="progress-text">En cours...</p></div>
</div>
<script>
async function startImport(){const u=document.getElementById('discogs-username').value.trim();if(!u)return alert("Entre ton username Discogs");document.getElementById('import-progress').classList.remove('hidden');document.getElementById('progress-text').textContent="Import en cours... ne ferme pas cette page.";const res=await fetch(`/import/discogs/${u}`,{method:'POST'});const data=await res.json();document.getElementById('progress-text').textContent=`✅ Import terminé : ${data.imported} nouveaux supports (${data.skipped} déjà présents).`;}
</script>
{% endblock %}
IMP_EOF

# ============ Route /add (page ajout) ============
# On ajoute une route simple pour servir la page d'ajout
cat >> app/routers/collection.py <<'ADDROUTE_EOF'

@router.get("/add", response_class=HTMLResponse)
async def add_page(request: Request, ean: str = Query(None)):
    require_auth(request)
    return request.app.state.templates.TemplateResponse("add_cd.html", {"request": request, "ean": ean})

@router.get("/scan", response_class=HTMLResponse)
async def scan_page(request: Request):
    require_auth(request)
    return request.app.state.templates.TemplateResponse("scan.html", {"request": request})
ADDROUTE_EOF

# ============ tests/conftest.py ============
cat > tests/conftest.py <<'CONF_EOF'
import os
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

os.environ.setdefault("DISCOGS_TOKEN", "test_token")
os.environ.setdefault("SECRET_KEY", "test_secret_key")
os.environ.setdefault("ADMIN_PASSWORD", "testpassword")
os.environ.setdefault("DISCOGS_USER_AGENT", "Test/1.0")
os.environ.setdefault("MUSICBRAINZ_USER_AGENT", "Test/1.0")

from app.database import Base, get_db
from app.main import app

@pytest_asyncio.fixture
async def db_engine():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest_asyncio.fixture
async def db_session(db_engine):
    factory = sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with factory() as session:
        yield session

@pytest_asyncio.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def auth_client(client):
    resp = await client.post("/login", data={"password": "testpassword"})
    assert resp.status_code == 303
    return client
CONF_EOF

# ============ tests/test_auth.py ============
cat > tests/test_auth.py <<'TA_EOF'
import pytest

@pytest.mark.asyncio
async def test_login_page(client):
    resp = await client.get("/login")
    assert resp.status_code == 200

@pytest.mark.asyncio
async def test_login_wrong_password(client):
    resp = await client.post("/login", data={"password": "mauvais"})
    assert resp.status_code == 401

@pytest.mark.asyncio
async def test_login_success(client):
    resp = await client.post("/login", data={"password": "testpassword"})
    assert resp.status_code == 303

@pytest.mark.asyncio
async def test_logout(auth_client):
    resp = await auth_client.get("/logout")
    assert resp.status_code == 303
TA_EOF

# ============ tests/test_collection.py ============
cat > tests/test_collection.py <<'TC_EOF'
import pytest
from app.models import CD
from sqlalchemy import select, func

@pytest.mark.asyncio
async def test_create_cd(auth_client, db_session):
    resp = await auth_client.post("/cd", data={"artist": "Radiohead", "title": "OK Computer", "year": 1997, "format": "CD", "genre": "Rock"})
    assert resp.status_code == 303
    cd = (await db_session.execute(select(CD))).scalars().first()
    assert cd.artist == "Radiohead"

@pytest.mark.asyncio
async def test_list_collection_empty(auth_client):
    resp = await auth_client.get("/collection")
    assert resp.status_code == 200

@pytest.mark.asyncio
async def test_search_by_artist(auth_client, db_session):
    db_session.add(CD(artist="Pink Floyd", title="Wish You Were Here", format="Vinyle"))
    await db_session.commit()
    resp = await auth_client.get("/collection?q=Pink")
    assert "Pink Floyd" in resp.text

@pytest.mark.asyncio
async def test_delete_cd(auth_client, db_session):
    cd = CD(artist="To Delete", title="Gone", format="CD")
    db_session.add(cd); await db_session.commit(); await db_session.refresh(cd)
    resp = await auth_client.delete(f"/cd/{cd.id}")
    assert resp.status_code == 303
    count = (await db_session.execute(select(func.count()).select_from(CD))).scalar()
    assert count == 0
TC_EOF

# ============ tests/test_export.py ============
cat > tests/test_export.py <<'TE_EOF'
import pytest
from app.models import CD, Track

@pytest.mark.asyncio
async def test_export_csv(auth_client, db_session):
    db_session.add(CD(artist="Artist", title="Title", format="CD", year=2020))
    await db_session.commit()
    resp = await auth_client.get("/export/csv")
    assert resp.status_code == 200
    assert "Artist" in resp.text

@pytest.mark.asyncio
async def test_export_json(auth_client, db_session):
    cd = CD(artist="Artist", title="Title", format="CD")
    db_session.add(cd); await db_session.commit(); await db_session.refresh(cd)
    db_session.add(Track(cd_id=cd.id, position="1", title="Song"))
    await db_session.commit()
    resp = await auth_client.get("/export/json")
    assert resp.status_code == 200
    data = resp.json()
    assert data[0]["artist"] == "Artist"
TE_EOF

# ============ README.md ============
cat > README.md <<'README_EOF'
# 🎵 CD Manager
Application web auto-hébergée pour gérer une collection de supports physiques
(CD, vinyles, cassettes, MiniDisc). Import Discogs, ajout par EAN/scan,
recherche, wantlist, exports CSV/JSON/PDF. Mono-utilisateur, pensée pour NAS.

## Stack
Python 3.12 + FastAPI · HTMX + Jinja2 · SQLite (SQLAlchemy async) · Docker

## Installation
1. `./setup.sh` (génère .env : token Discogs, mot de passe, SECRET_KEY)
2. `docker compose up -d --build`
3. Ouvrir `http://IP-DU-NAS:8090`

## Import Discogs
Menu "Import Discogs" → username → lancer. Idempotent (pas de doublons).
~25-30 min pour 1200 références (rate limit ~1 req/s).

## Scan téléphone
Nécessite HTTPS (reverse proxy NAS ou Tailscale).

## Tests
`pip install -r requirements.txt -r requirements-dev.txt && pytest -v`

## Sécurité
`.env` et `data/` sont exclus de Git via `.gitignore`. Ne jamais les pousser.
README_EOF

echo "✅ Génération terminée !"
echo "→ Vérifie : ls -R app tests"
echo "→ Puis : ./setup.sh && docker compose up -d --build"
