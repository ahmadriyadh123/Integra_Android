# app/features/elearning/router.py
import io
import os
import zipfile
import logging
import base64
import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.core.config import settings
from app.features.elearning.schemas import APIResponseCourseList, APIResponseCourseDetail
from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService

logger = logging.getLogger(__name__)

def generate_sample_scorm_zip(title: str) -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        manifest_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<manifest identifier="MANIFEST-1" version="1.0" xmlns="http://www.imsproject.org/xsd/imscp_rootv1p1p2">
  <metadata>
    <schema>ADL SCORM</schema>
    <schemaversion>1.2</schemaversion>
  </metadata>
  <organizations default="ORG-1">
    <organization identifier="ORG-1">
      <title>{title}</title>
      <item identifier="ITEM-1" identifierref="RES-1">
        <title>{title}</title>
      </item>
    </organization>
  </organizations>
  <resources>
    <resource identifier="RES-1" type="webcontent" adlcp:scormtype="sco" href="index.html">
      <file href="index.html"/>
      <file href="styles.css"/>
      <file href="scorm.js"/>
      <file href="app.js"/>
    </resource>
  </resources>
</manifest>"""
        zf.writestr("imsmanifest.xml", manifest_content)

        html_content = f"""<!doctype html>
<html lang="id">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>{title}</title>
        <link rel="stylesheet" href="styles.css">
    </head>
    <body>
        <header class="topbar">
            <div class="brand">
                <div class="brand-logo">🕌</div>
                <div>
                    <div class="brand-title">PAI Kelas 1</div>
                    <div class="brand-sub">Pendidikan Agama Islam dan Budi Pekerti</div>
                </div>
            </div>
            <div class="progress-wrap">
                <div class="progress-track">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
                <div class="progress-label" id="progressLabel">0% selesai</div>
            </div>
        </header>
        <div class="layout">
            <aside class="sidebar">
                <div class="nav-title">MULAI BELAJAR</div>
                <button class="nav-btn active" data-target="home">
                    <span class="nav-icon">🏡</span>
                    <span>Beranda</span>
                </button>
                <button class="nav-btn" data-target="video">
                    <span class="nav-icon">🎬</span>
                    <span>Video Pengantar</span>
                </button>
                <div class="nav-title">MATERI</div>
                <button class="nav-btn" data-target="bab-1">
                    <span class="nav-icon">📖</span>
                    <span>
                        Bab 1<br>
                        <small>Aku Cinta Al-Qur’an</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-2">
                    <span class="nav-icon">✨</span>
                    <span>
                        Bab 2<br>
                        <small>Mengenal Rukun Iman</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-3">
                    <span class="nav-icon">🌿</span>
                    <span>
                        Bab 3<br>
                        <small>Aku Suka Membaca Basmalah dan Hamdalah</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-4">
                    <span class="nav-icon">🕌</span>
                    <span>
                        Bab 4<br>
                        <small>Mengenal Rukun Islam</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-5">
                    <span class="nav-icon">🌟</span>
                    <span>
                        Bab 5<br>
                        <small>Nabi dan Rasul Panutanku</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-6">
                    <span class="nav-icon">📚</span>
                    <span>
                        Bab 6<br>
                        <small>Al-Qur’an Pedoman Hidupku</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-7">
                    <span class="nav-icon">💗</span>
                    <span>
                        Bab 7<br>
                        <small>Kasih Sayang terhadap Sesama</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-8">
                    <span class="nav-icon">🙏</span>
                    <span>
                        Bab 8<br>
                        <small>Aku Suka Berterima Kasih dan Disiplin</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-9">
                    <span class="nav-icon">💧</span>
                    <span>
                        Bab 9<br>
                        <small>Membiasakan Hidup Bersih</small>
                    </span>
                </button>
                <button class="nav-btn" data-target="bab-10">
                    <span class="nav-icon">🌍</span>
                    <span>
                        Bab 10<br>
                        <small>Nabi Adam a.s. Manusia Pertama</small>
                    </span>
                </button>
                <div class="nav-title">PENUTUP</div>
                <button class="nav-btn" data-target="summary">
                    <span class="nav-icon">📝</span>
                    <span>Rangkuman</span>
                </button>
                <button class="nav-btn" data-target="quiz">
                    <span class="nav-icon">🏆</span>
                    <span>Kuis Akhir</span>
                </button>
            </aside>
            <main>
                <section class="screen active" id="home">
                    <div class="hero">
                        <div class="hero-grid">
                            <div>
                                <span class="kicker">BELAJAR IMAN, IBADAH, DAN AKHLAK</span>
                                <h1>Aku Anak Saleh dan Salehah</h1>
                                <p>Petualangan belajar Pendidikan Agama Islam kelas satu melalui narasi, aktivitas interaktif, latihan, dan rangkuman.</p>
                                <div class="cta-row">
                                    <button class="primary" data-target="video">▶ Mulai dari Video</button>
                                    <button class="secondary" data-target="bab-1">Masuk Bab 1</button>
                                </div>
                            </div>
                            <div class="hero-card">
                                <div class="big" style="font-size:48px;">📖</div>
                                <h2>Mari Belajar</h2>
                                <div class="mini-values">
                                    <span>🤲 Beriman</span>
                                    <span>💗 Penyayang</span>
                                    <span>🧼 Bersih</span>
                                    <span>⏰ Disiplin</span>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="safety-banner">
                        <strong>Pendampingan penting:</strong>
                        pelafalan Al-Qur’an, huruf Arab, tajwid, wudu, dan tayamum harus dipraktikkan bersama guru, orang tua, atau pembimbing yang kompeten. Audio paket ini merupakan narasi penjelasan Bahasa Indonesia.
                    </div>
                    <div class="footer-note">Materi disusun berdasarkan tema dan struktur buku Pendidikan Agama Islam dan Budi Pekerti Kelas I.</div>
                </section>
                <section class="screen" id="video">
                    <div class="lesson-head">
                        <div>
                            <span class="kicker">VIDEO PEMBUKA</span>
                            <h2 class="lesson-title">Petualangan PAI Kelas Satu</h2>
                            <div class="lesson-sub">Tonton bersama guru atau orang tua dan kenali sepuluh bab yang akan dipelajari.</div>
                        </div>
                        <div class="lesson-icon">🎬</div>
                    </div>
                    <div class="arabic-note" style="background:#ECFDF5; padding:16px; border-radius:12px; border-left:4px solid #059669; font-size:13px; color:#065F46;">
                        <strong>Catatan:</strong>
                        Video ini berisi pengantar topik. Latihan bacaan Arab dilakukan secara langsung bersama pembimbing.
                    </div>
                    <div class="next-row" style="margin-top:20px;">
                        <button class="primary" data-target="bab-1">Mulai Bab 1 →</button>
                    </div>
                </section>
                <section class="screen" id="bab-1"></section>
                <section class="screen" id="bab-2"></section>
                <section class="screen" id="bab-3"></section>
                <section class="screen" id="bab-4"></section>
                <section class="screen" id="bab-5"></section>
                <section class="screen" id="bab-6"></section>
                <section class="screen" id="bab-7"></section>
                <section class="screen" id="bab-8"></section>
                <section class="screen" id="bab-9"></section>
                <section class="screen" id="bab-10"></section>
                <section class="screen" id="summary">
                    <div class="lesson-head">
                        <div>
                            <span class="kicker">RANGKUMAN</span>
                            <h2 class="lesson-title">Imanku, Ibadahku, dan Akhlakku</h2>
                            <div class="lesson-sub">Ingat kembali hal penting dari sepuluh bab.</div>
                        </div>
                        <div class="lesson-icon">📝</div>
                    </div>
                    <div class="summary-grid">
                        <div class="summary-card">
                            <div style="font-size:36px">📖</div>
                            <h3>Bab 1: Aku Cinta Al-Qur’an</h3>
                            <p>Mengenal Al-Qur’an sebagai kitab suci, mengenal huruf hijaiah dan harakat, serta membiasakan belajar Surah Al-Fatihah dengan bimbingan.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">✨</div>
                            <h3>Bab 2: Mengenal Rukun Iman</h3>
                            <p>Menyebutkan enam rukun iman dan menunjukkan sikap beriman kepada Allah serta mencintai para rasul.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">🌿</div>
                            <h3>Bab 3: Aku Suka Membaca Basmalah dan Hamdalah</h3>
                            <p>Membiasakan membaca basmalah sebelum kegiatan baik, hamdalah setelah selesai, bersikap santun, dan mensyukuri nikmat Allah.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">🕌</div>
                            <h3>Bab 4: Mengenal Rukun Islam</h3>
                            <p>Menyebutkan lima rukun Islam, mengenal dua kalimat syahadat, serta bangga menjadi anak muslim yang berakhlak baik.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">🌟</div>
                            <h3>Bab 5: Nabi dan Rasul Panutanku</h3>
                            <p>Mengenal nabi dan rasul, mengetahui bahwa ada 25 nabi dan rasul yang wajib diketahui, serta meneladani perilaku sederhana mereka.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">📚</div>
                            <h3>Bab 6: Al-Qur’an Pedoman Hidupku</h3>
                            <p>Menguatkan pengenalan harakat dan huruf hijaiah, belajar Surah Al-Ikhlas dengan bimbingan, serta memahami pesan bahwa Allah Maha Esa.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">💗</div>
                            <h3>Bab 7: Kasih Sayang terhadap Sesama</h3>
                            <p>Mengenal Ar-Rahman dan Ar-Rahim serta membiasakan kasih sayang kepada keluarga, teman, hewan, dan lingkungan.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">🙏</div>
                            <h3>Bab 8: Aku Suka Berterima Kasih dan Disiplin</h3>
                            <p>Membiasakan berterima kasih dengan santun dan menerapkan disiplin mulai dari diri sendiri.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">💧</div>
                            <h3>Bab 9: Membiasakan Hidup Bersih</h3>
                            <p>Memahami pentingnya kebersihan, mengenal bersuci, serta mempraktikkan wudu dan tayamum dengan pendampingan.</p>
                        </div>
                        <div class="summary-card">
                            <div style="font-size:36px">🌍</div>
                            <h3>Bab 10: Nabi Adam a.s. Manusia Pertama</h3>
                            <p>Mengenal kisah Nabi Adam a.s. sebagai manusia pertama dan mengambil teladan tentang taat, bertanggung jawab, serta memohon ampun.</p>
                        </div>
                    </div>
                    <div class="panel" style="background:#ECFDF5; border:1px solid #A7F3D0; padding:20px; border-radius:16px; margin-top:20px;">
                        <h3 style="color:#065F46; margin-bottom:8px;">⭐ Tekadku</h3>
                        <p style="color:#047857; font-size:14px; margin:0;">Aku akan mencintai Al-Qur’an, beriman kepada Allah, rajin beribadah, jujur, santun, penyayang, berterima kasih, disiplin, dan menjaga kebersihan. Aku belajar bacaan dan praktik ibadah bersama guru atau orang tua.</p>
                    </div>
                    <div class="next-row" style="margin-top:20px;">
                        <button class="primary" data-target="quiz">Kerjakan Kuis Akhir →</button>
                    </div>
                </section>
                <section class="screen" id="quiz">
                    <div class="lesson-head">
                        <div>
                            <span class="kicker">KUIS AKHIR</span>
                            <h2 class="lesson-title">Uji Kemampuanku</h2>
                            <div class="lesson-sub">Pilih jawaban yang paling tepat. Nilai kelulusan 70.</div>
                        </div>
                        <div class="lesson-icon">🏆</div>
                    </div>
                    <div class="final-quiz" id="finalQuizBox">
                        <div class="quiz-top">
                            <span id="quizNo">Soal 1 dari 4</span>
                            <span id="quizScore">Skor: 0</span>
                        </div>
                        <div class="final-prompt" id="finalPrompt"></div>
                        <div class="final-options" id="finalOptions"></div>
                    </div>
                </section>
            </main>
        </div>
        <nav class="mobile-nav">
            <button data-target="home" class="active">
                🏡<br>Beranda
            </button>
            <button data-target="bab-1">
                📖<br>Materi
            </button>
            <button data-target="summary">
                📝<br>Rangkuman
            </button>
            <button data-target="quiz">
                🏆<br>Kuis
            </button>
        </nav>
        <script src="scorm.js"></script>
        <script src="app.js"></script>
    </body>
</html>"""
        zf.writestr("index.html", html_content)

        css_content = """* { box-sizing: border-box; margin: 0; padding: 0; }
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background: #F8FAFC; color: #0F172A; min-height: 100vh;
    display: flex; flex-direction: column; padding-bottom: 60px;
}
.topbar {
    background: #059669; color: white; padding: 14px 20px;
    display: flex; align-items: center; justify-content: space-between;
    box-shadow: 0 4px 12px rgba(5, 150, 105, 0.15); position: sticky; top: 0; z-index: 100;
}
.brand { display: flex; align-items: center; gap: 12px; }
.brand-logo { font-size: 28px; }
.brand-title { font-size: 15px; font-weight: 800; }
.brand-sub { font-size: 11px; opacity: 0.9; }
.progress-wrap { display: flex; align-items: center; gap: 10px; width: 160px; }
.progress-track { flex: 1; background: rgba(255,255,255,0.25); height: 8px; border-radius: 4px; overflow: hidden; }
.progress-fill { background: #10B981; height: 100%; width: 0%; transition: width 0.3s; }
.progress-label { font-size: 11px; font-weight: 600; white-space: nowrap; }

.layout { display: flex; flex: 1; }
.sidebar {
    width: 260px; background: white; border-right: 1px solid #E2E8F0;
    padding: 16px; display: flex; flex-direction: column; gap: 4px;
    overflow-y: auto; max-height: calc(100vh - 60px);
}
.nav-title { font-size: 10px; font-weight: 800; color: #94A3B8; margin: 12px 0 4px 8px; letter-spacing: 0.5px; }
.nav-btn {
    display: flex; align-items: center; gap: 10px; padding: 10px 12px;
    border: none; background: transparent; color: #475569; font-size: 13px;
    font-weight: 600; border-radius: 10px; cursor: pointer; text-align: left;
    transition: all 0.2s; width: 100%;
}
.nav-btn:hover { background: #ECFDF5; color: #059669; }
.nav-btn.active { background: #059669; color: white; }
.nav-icon { font-size: 18px; }
.nav-btn small { font-size: 11px; opacity: 0.8; font-weight: 400; display: block; }

main { flex: 1; padding: 24px; max-width: 900px; margin: 0 auto; width: 100%; }
.screen { display: none; }
.screen.active { display: block; animation: fadeIn 0.3s ease; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }

.hero { background: white; border-radius: 20px; padding: 28px; border: 1px solid #E2E8F0; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
.kicker { color: #059669; font-size: 11px; font-weight: 800; letter-spacing: 1px; }
h1 { font-size: 24px; color: #0F172A; margin: 8px 0 12px; }
p { font-size: 14px; color: #475569; line-height: 1.6; margin-bottom: 20px; }
.cta-row { display: flex; gap: 12px; margin-top: 20px; }
button.primary { background: #059669; color: white; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 700; cursor: pointer; font-size: 14px; }
button.secondary { background: #ECFDF5; color: #059669; border: 1px solid #A7F3D0; padding: 12px 24px; border-radius: 12px; font-weight: 700; cursor: pointer; font-size: 14px; }
button.primary:hover { background: #047857; }
button.secondary:hover { background: #D1FAE5; }

.mini-values { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
.mini-values span { background: #F1F5F9; padding: 4px 12px; border-radius: 20px; font-size: 12px; color: #334155; font-weight: 600; }
.safety-banner { background: #FEF3C7; border-left: 4px solid #F59E0B; padding: 16px; border-radius: 12px; font-size: 13px; color: #92400E; margin-top: 24px; }
.footer-note { margin-top: 24px; font-size: 12px; color: #94A3B8; text-align: center; }

.lesson-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.lesson-title { font-size: 20px; color: #0F172A; margin-top: 4px; }
.lesson-sub { font-size: 13px; color: #64748B; }
.lesson-icon { font-size: 36px; }

.summary-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; margin: 20px 0; }
.summary-card { background: white; border-radius: 16px; border: 1px solid #E2E8F0; padding: 20px; }
.summary-card h3 { font-size: 15px; color: #0F172A; margin: 12px 0 8px; }
.summary-card p { font-size: 13px; color: #64748B; margin: 0; }

.final-quiz { background: white; border-radius: 16px; border: 1px solid #E2E8F0; padding: 24px; }
.quiz-top { display: flex; justify-content: space-between; font-size: 13px; font-weight: 700; color: #059669; margin-bottom: 16px; }
.final-prompt { font-size: 16px; font-weight: 700; color: #0F172A; margin-bottom: 20px; }
.final-options button {
    display: block; width: 100%; text-align: left; padding: 14px 18px; margin-bottom: 10px;
    background: #F8FAFC; border: 1px solid #CBD5E1; border-radius: 12px; font-size: 14px;
    color: #334155; cursor: pointer; transition: all 0.2s; font-weight: 500;
}
.final-options button:hover { background: #ECFDF5; border-color: #059669; color: #059669; }

.mobile-nav { display: none; position: fixed; bottom: 0; left: 0; right: 0; background: white; border-top: 1px solid #E2E8F0; padding: 8px 16px; justify-content: space-around; z-index: 99; }
.mobile-nav button { border: none; background: transparent; font-size: 11px; color: #64748B; text-align: center; cursor: pointer; font-weight: 600; }
.mobile-nav button.active { color: #059669; }

@media (max-width: 768px) {
    .sidebar { display: none; }
    .mobile-nav { display: flex; }
    .progress-wrap { width: 110px; }
}"""
        zf.writestr("styles.css", css_content)

        scorm_js = """(function(window){
    var API = null;
    function getAPI() {
        if (window.API) return window.API;
        if (window.parent && window.parent.API) return window.parent.API;
        if (window.top && window.top.API) return window.top.API;
        return {
            LMSInitialize: function() { return "true"; },
            LMSFinish: function() { return "true"; },
            LMSGetValue: function() { return ""; },
            LMSSetValue: function() { return "true"; },
            LMSCommit: function() { return "true"; }
        };
    }
    window.ScormAPI = {
        init: function() {
            API = getAPI();
            try { API.LMSInitialize(""); } catch(e){}
        },
        saveProgress: function(lessonLocation, status, score) {
            try {
                if (API) {
                    if (lessonLocation) API.LMSSetValue("cmi.core.lesson_location", lessonLocation);
                    if (status) API.LMSSetValue("cmi.core.lesson_status", status);
                    if (score !== undefined) API.LMSSetValue("cmi.core.score.raw", score.toString());
                    API.LMSCommit("");
                }
            } catch(e){}
        },
        finish: function() {
            try { if (API) API.LMSFinish(""); } catch(e){}
        }
    };
})(window);"""
        zf.writestr("scorm.js", scorm_js)

        app_js = """document.addEventListener("DOMContentLoaded", function () {
    if (window.ScormAPI) ScormAPI.init();

    const babData = {
        "bab-1": {
            title: "Bab 1: Aku Cinta Al-Qur'an",
            icon: "📖",
            desc: "Al-Qur'an adalah kitab suci umat Islam. Mari belajar huruf hijaiah, harakat (fathah, kasrah, dammah), dan Surah Al-Fatihah.",
            points: [
                "Al-Qur'an diturunkan kepada Nabi Muhammad SAW.",
                "Membaca Al-Qur'an mendapat pahala melimpah dari Allah SWT.",
                "Surah Al-Fatihah artinya Pembukaan dan terdiri dari 7 ayat."
            ]
        },
        "bab-2": {
            title: "Bab 2: Mengenal Rukun Iman",
            icon: "✨",
            desc: "Rukun Iman ada 6 perkara yang wajib diyakini oleh setiap muslim.",
            points: [
                "1. Iman kepada Allah SWT",
                "2. Iman kepada Malaikat-Malaikat Allah",
                "3. Iman kepada Kitab-Kitab Allah",
                "4. Iman kepada Rasul-Rasul Allah",
                "5. Iman kepada Hari Kiamat",
                "6. Iman kepada Qada dan Qadar"
            ]
        },
        "bab-3": {
            title: "Bab 3: Aku Suka Membaca Basmalah dan Hamdalah",
            icon: "🌿",
            desc: "Membiasakan berdoa dan menyebut nama Allah sebelum dan sesudah beraktivitas.",
            points: [
                "Membaca 'Bismillahirrahmanirrahim' sebelum memulai kegiatan baik.",
                "Membaca 'Alhamdulillahirabbil 'alamin' setelah selesai kegiatan.",
                "Bersyukur atas nikmat kesehatan, keluarga, dan kesempatan belajar."
            ]
        },
        "bab-4": {
            title: "Bab 4: Mengenal Rukun Islam",
            icon: "🕌",
            desc: "Rukun Islam adalah 5 tiang utama dalam beragama Islam.",
            points: [
                "1. Mengucapkan Dua Kalimat Syahadat",
                "2. Mendirikan Shalat 5 Waktu",
                "3. Menunaikan Zakat",
                "4. Berpuasa di Bulan Ramadan",
                "5. Menunaikan Ibadah Haji bagi yang mampu"
            ]
        },
        "bab-5": {
            title: "Bab 5: Nabi dan Rasul Panutanku",
            icon: "🌟",
            desc: "Meneladani sifat jujur, amanah, dan kasih sayang para nabi dan rasul.",
            points: [
                "Ada 25 Nabi dan Rasul yang wajib diketahui.",
                "Nabi Muhammad SAW adalah Nabi dan Rasul terakhir (Khatamul Anbiya).",
                "Meneladani perilaku jujur (Siddiq) dan terpercaya (Amanah)."
            ]
        },
        "bab-6": {
            title: "Bab 6: Al-Qur'an Pedoman Hidupku",
            icon: "📚",
            desc: "Belajar Surah Al-Ikhlas dan mengamalkan pesan bahwa Allah Maha Esa.",
            points: [
                "Surah Al-Ikhlas menegaskan bahwa Allah adalah Tuhan Yang Maha Esa.",
                "Allah tidak beranak dan tidak diperanakkan.",
                "Hanya kepada Allah kita menyembah dan memohon pertolongan."
            ]
        },
        "bab-7": {
            title: "Bab 7: Kasih Sayang terhadap Sesama",
            icon: "💗",
            desc: "Mengenal Asmaul Husna Ar-Rahman (Maha Pengasih) dan Ar-Rahim (Maha Penyayang).",
            points: [
                "Menyayangi orang tua, guru, dan teman di sekolah.",
                "Menyayangi hewan dan menjaga kelestarian lingkungan sekitar.",
                "Tidak suka bertengkar dan saling membantu dalam kebaikan."
            ]
        },
        "bab-8": {
            title: "Bab 8: Aku Suka Berterima Kasih dan Disiplin",
            icon: "🙏",
            desc: "Membiasakan sikap santun, berterima kasih, dan disiplin waktu.",
            points: [
                "Mengucapkan terima kasih jika dibantu atau diberi kebaikan.",
                "Disiplin bangun pagi, shalat, dan belajar tepat waktu.",
                "Merapikan kembali tempat tidur dan perlengkapan sekolah."
            ]
        },
        "bab-9": {
            title: "Bab 9: Membiasakan Hidup Bersih",
            icon: "💧",
            desc: "Kebersihan adalah sebagian dari iman (An-Nadhofatu minal iman).",
            points: [
                "Mencuci tangan, bersuci (thaharah), dan wudu sebelum shalat.",
                "Mengenal tayamum sebagai pengganti wudu jika tidak ada air.",
                "Menjaga kebersihan pakaian, rumah, dan ruang kelas."
            ]
        },
        "bab-10": {
            title: "Bab 10: Nabi Adam a.s. Manusia Pertama",
            icon: "🌍",
            desc: "Meneladani kisah Nabi Adam a.s. dalam hal taat dan memohon ampunan Allah.",
            points: [
                "Nabi Adam a.s. diciptakan oleh Allah dari tanah sebagai manusia pertama.",
                "Belajar dari kesalahan dan segera memohon ampun (bertaubat) kepada Allah.",
                "Selalu bersikap jujur dan bertanggung jawab atas setiap perbuatan."
            ]
        }
    };

    function getNextBab(currentId) {
        const keys = Object.keys(babData);
        const idx = keys.indexOf(currentId);
        if (idx >= 0 && idx < keys.length - 1) return keys[idx + 1];
        return "summary";
    }

    Object.keys(babData).forEach(babId => {
        const sec = document.getElementById(babId);
        if (sec) {
            const data = babData[babId];
            sec.innerHTML = `
                <div class="lesson-head">
                    <div>
                        <span class="kicker">MATERI PEMBELAJARAN</span>
                        <h2 class="lesson-title">${data.title}</h2>
                        <div class="lesson-sub">${data.desc}</div>
                    </div>
                    <div class="lesson-icon">${data.icon}</div>
                </div>
                <div class="summary-card" style="margin-bottom:20px;">
                    <h3 style="font-size:15px; margin-bottom:12px; color:#059669;">Ringkasan Poin Pembelajaran:</h3>
                    <ul style="margin-left:20px; font-size:14px; color:#334155; line-height:1.8;">
                        ${data.points.map(p => `<li>${p}</li>`).join('')}
                    </ul>
                </div>
                <div class="next-row" style="display:flex; justify-content:space-between; margin-top:20px;">
                    <button class="secondary nav-btn-action" data-target="home">← Kembali ke Beranda</button>
                    <button class="primary nav-btn-action" data-target="${getNextBab(babId)}">Lanjut Pembelajaran →</button>
                </div>
            `;
        }
    });

    const allScreens = document.querySelectorAll(".screen");
    let visitedScreens = new Set(["home"]);

    function switchScreen(targetId) {
        allScreens.forEach(s => s.classList.remove("active"));
        const targetScreen = document.getElementById(targetId);
        if (targetScreen) {
            targetScreen.classList.add("active");
            visitedScreens.add(targetId);
            window.scrollTo({ top: 0, behavior: 'smooth' });

            document.querySelectorAll(".nav-btn, .mobile-nav button").forEach(b => {
                b.classList.toggle("active", b.getAttribute("data-target") === targetId);
            });

            const progress = Math.min(100, Math.round((visitedScreens.size / 14) * 100));
            const fill = document.getElementById("progressFill");
            const lbl = document.getElementById("progressLabel");
            if (fill) fill.style.width = progress + "%";
            if (lbl) lbl.innerText = progress + "% selesai";

            if (window.ScormAPI) {
                ScormAPI.saveProgress(targetId, progress >= 80 ? "completed" : "incomplete");
            }
        }
    }

    document.addEventListener("click", function (e) {
        const btn = e.target.closest("[data-target]");
        if (btn) {
            const target = btn.getAttribute("data-target");
            switchScreen(target);
        }
    });

    const quizQuestions = [
        {
            q: "Siapakah Nabi dan Rasul terakhir yang menjadi teladan umat Islam?",
            options: ["A. Nabi Adam a.s.", "B. Nabi Ibrahim a.s.", "C. Nabi Muhammad SAW"],
            answer: 2
        },
        {
            q: "Kalimat yang diucapkan sebelum memulai pekerjaan baik adalah...",
            options: ["A. Alhamdulillah", "B. Bismillah", "C. Astaghfirullah"],
            answer: 1
        },
        {
            q: "Ada berapakah jumlah Rukun Islam?",
            options: ["A. 5 Perkara", "B. 6 Perkara", "C. 10 Perkara"],
            answer: 0
        },
        {
            q: "Kitab suci petunjuk hidup bagi umat Islam adalah...",
            options: ["A. Taurat", "B. Injil", "C. Al-Qur'an"],
            answer: 2
        }
    ];

    let currentQ = 0;
    let score = 0;

    function renderQuiz() {
        const box = document.getElementById("finalQuizBox");
        if (!box) return;

        if (currentQ >= quizQuestions.length) {
            const finalScore = Math.round((score / quizQuestions.length) * 100);
            const passed = finalScore >= 70;
            box.innerHTML = `
                <div style="text-align:center; padding: 20px 0;">
                    <div style="font-size:60px; margin-bottom:16px;">${passed ? '🏆' : '📚'}</div>
                    <h2 style="color:#0F172A; font-size:22px; margin-bottom:8px;">${passed ? 'Selamat! Anda Lulus Kuis Akhir' : 'Tetap Semangat! Coba Lagi'}</h2>
                    <p style="color:#64748B; font-size:14px;">Nilai Akhir Anda: <strong style="color:#059669; font-size:20px;">${finalScore}</strong> (Batas Kelulusan: 70)</p>
                    <button class="primary" onclick="location.reload()" style="margin-top:20px;">🔄 Ulangi Pembelajaran</button>
                </div>
            `;

            if (window.ScormAPI) {
                ScormAPI.saveProgress("quiz", passed ? "passed" : "failed", finalScore);
            }
            return;
        }

        const qData = quizQuestions[currentQ];
        const qNo = document.getElementById("quizNo");
        const qScore = document.getElementById("quizScore");
        const prompt = document.getElementById("finalPrompt");
        const optsDiv = document.getElementById("finalOptions");

        if (qNo) qNo.innerText = `Soal ${currentQ + 1} dari ${quizQuestions.length}`;
        if (qScore) qScore.innerText = `Skor: ${score * 25}`;
        if (prompt) prompt.innerText = qData.q;

        if (optsDiv) {
            optsDiv.innerHTML = qData.options.map((opt, idx) => `
                <button onclick="checkAnswer(${idx})">${opt}</button>
            `).join('');
        }
    }

    window.checkAnswer = function (selectedIdx) {
        if (selectedIdx === quizQuestions[currentQ].answer) {
            score++;
        }
        currentQ++;
        renderQuiz();
    };

    renderQuiz();
});"""
        zf.writestr("app.js", app_js)

    return buf.getvalue()

router = APIRouter(
    prefix="/elearning",
    tags=["Menu E-Learning"]
)

@router.get("/courses", response_model=APIResponseCourseList)
async def get_courses(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = ElearningRepository(db)
        service = ElearningService(repo)
        data = await service.get_courses_list()

        return APIResponseCourseList(
            success=True,
            message="Berhasil mengambil daftar kursus E-Learning",
            data=data
        )
    except Exception as e:
        logger.error(f"[elearning/courses] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data kursus: {str(e)}"
        )

@router.get("/courses/{course_id}", response_model=APIResponseCourseDetail)
async def get_course_detail(
    course_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = ElearningRepository(db)
        service = ElearningService(repo)
        data = await service.get_course_detail(course_id=course_id)

        if not data:
            return APIResponseCourseDetail(
                success=False,
                message="Kursus E-Learning tidak ditemukan",
                data=None
            )

        return APIResponseCourseDetail(
            success=True,
            message="Berhasil mengambil detail kursus E-Learning",
            data=data
        )
    except Exception as e:
        logger.error(f"[elearning/courses/{course_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail kursus: {str(e)}"
        )

@router.get("/content/{attachment_id}/{path:path}")
async def download_attachment_content(
    attachment_id: int,
    path: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Proxy endpoint untuk mengunduh materi SCORM/PDF dari Odoo via middleware.
    Selain mengembalikan ZIP/PDF, endpoint ini juga dapat mengekstrak paket ZIP dan
    menyajikan file internal (mis. index.html) dengan injeksi SCORM shim sehingga
    client (WebView) tidak perlu melakukan injection di sisi aplikasi.
    """
    repo = ElearningRepository(db)
    attachment = await repo.get_attachment_by_id(attachment_id)
    mimetype = attachment.get("mimetype") if attachment else "application/octet-stream"

    # Helper: inject small shim script before </head>
    def inject_shim_into_html(html_bytes: bytes) -> bytes:
        try:
            html = html_bytes.decode('utf-8')
        except Exception:
            html = html_bytes.decode('latin-1', errors='ignore')
        shim = r"""
<script>
(function(){
  function send(type,payload){
    var msg = JSON.stringify({type:type,payload:payload||{}});
    if (window.flutter_inappwebview && window.flutter_inappwebview.postMessage) {
      window.flutter_inappwebview.postMessage(msg);
    } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ScormHost){
      try{ window.webkit.messageHandlers.ScormHost.postMessage(msg);}catch(e){}
    } else if (window.parent && window.parent !== window && window.parent.ScormHost && window.parent.ScormHost.postMessage) {
      try{ window.parent.ScormHost.postMessage(msg);}catch(e){}
    } else {
      // fallback to console
      console.log('[SCORM-SHIM] no host channel');
    }
  }
  window.API = window.API || {
    LMSInitialize: function(){ send('initialize',{api:'1.2'}); return 'true'; },
    LMSFinish: function(){ send('finish',{api:'1.2'}); return 'true'; },
    LMSGetValue: function(k){ send('get',{key:k,api:'1.2'}); return ''; },
    LMSSetValue: function(k,v){ send('set',{key:k,value:v,api:'1.2'}); return 'true'; },
    LMSCommit: function(){ send('commit',{api:'1.2'}); return 'true'; }
  };
  window.API_1484_11 = window.API_1484_11 || {
    Initialize: function(){ send('initialize',{api:'2004'}); return 'true'; },
    Terminate: function(){ send('finish',{api:'2004'}); return 'true'; },
    GetValue: function(k){ send('get',{key:k,api:'2004'}); return ''; },
    SetValue: function(k,v){ send('set',{key:k,value:v,api:'2004'}); return 'true'; },
    Commit: function(){ send('commit',{api:'2004'}); return 'true'; }
  };
})();
</script>
"""
        if '</head>' in html.lower():
            # naive inject: find last occurrence of </head> (case-insensitive)
            idx = html.lower().rfind('</head>')
            injected = html[:idx] + shim + html[idx:]
            return injected.encode('utf-8')
        else:
            # append at start
            return (shim + html).encode('utf-8')

    # 1. If attachment binary stored in DB (db_datas)
    if attachment and attachment.get("db_datas"):
        file_bytes = base64.b64decode(attachment["db_datas"])
        # If ZIP, allow serving internal files
        if mimetype == 'application/zip':
            try:
                with zipfile.ZipFile(io.BytesIO(file_bytes)) as z:
                    requested = path.lstrip('/') or ''
                    # Determine index if root requested
                    if requested == '' or requested.endswith('/'):
                        # choose first index.html candidate
                        candidates = [n for n in z.namelist() if n.lower().endswith('index.html')]
                        if not candidates:
                            raise KeyError('no index')
                        requested = candidates[0]
                    # normalize names in zip (they use '/'). Try direct
                    if requested not in z.namelist():
                        # try with and without leading ./
                        alt = requested.lstrip('./')
                        if alt in z.namelist():
                            requested = alt
                        else:
                            # try to find by basename
                            basename = os.path.basename(requested)
                            matches = [n for n in z.namelist() if n.lower().endswith('/' + basename) or n.lower() == basename.lower()]
                            if matches:
                                requested = matches[0]
                            else:
                                raise KeyError(requested)
                    data = z.read(requested)
                    # If HTML, inject shim
                    if requested.lower().endswith('.html') or requested.lower().endswith('.htm'):
                        injected = inject_shim_into_html(data)
                        return Response(content=injected, media_type='text/html')
                    # otherwise determine media_type heuristically
                    ext = os.path.splitext(requested)[1].lstrip('.').lower()
                    media = {
                        'css': 'text/css', 'js': 'application/javascript', 'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'gif': 'image/gif', 'svg':'image/svg+xml', 'woff':'font/woff', 'woff2':'font/woff2'
                    }.get(ext, mimetype)
                    return Response(content=data, media_type=media)
            except KeyError:
                raise HTTPException(status_code=404, detail='File not found inside SCORM package')
        else:
            # non-zip binary stored in db
            return Response(content=file_bytes, media_type=mimetype)

    # 2. Filestore local
    if attachment and attachment.get("store_fname") and getattr(settings, "ODOO_FILESTORE_PATH", None):
        filestore_file = os.path.join(settings.ODOO_FILESTORE_PATH, attachment["store_fname"])
        if os.path.exists(filestore_file):
            # If the stored file is a zip and we want an internal path, handle similarly
            if mimetype == 'application/zip':
                try:
                    with zipfile.ZipFile(filestore_file) as z:
                        requested = path.lstrip('/') or ''
                        if requested == '' or requested.endswith('/'):
                            candidates = [n for n in z.namelist() if n.lower().endswith('index.html')]
                            if not candidates:
                                raise KeyError('no index')
                            requested = candidates[0]
                        if requested not in z.namelist():
                            alt = requested.lstrip('./')
                            if alt in z.namelist():
                                requested = alt
                            else:
                                basename = os.path.basename(requested)
                                matches = [n for n in z.namelist() if n.lower().endswith('/' + basename) or n.lower() == basename.lower()]
                                if matches:
                                    requested = matches[0]
                                else:
                                    raise KeyError(requested)
                        data = z.read(requested)
                        if requested.lower().endswith('.html') or requested.lower().endswith('.htm'):
                            injected = inject_shim_into_html(data)
                            return Response(content=injected, media_type='text/html')
                        ext = os.path.splitext(requested)[1].lstrip('.').lower()
                        media = {
                            'css': 'text/css', 'js': 'application/javascript', 'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'gif': 'image/gif', 'svg':'image/svg+xml', 'woff':'font/woff', 'woff2':'font/woff2'
                        }.get(ext, mimetype)
                        return Response(content=data, media_type=media)
                except KeyError:
                    raise HTTPException(status_code=404, detail='File not found inside SCORM package')
            else:
                try:
                    with open(filestore_file, 'rb') as f:
                        return Response(content=f.read(), media_type=mimetype)
                except Exception as e:
                    logger.error(f"Failed to read filestore file {filestore_file}: {e}")

    # 3. Proxy dari Odoo lokal jika Odoo 8069 berjalan di host yang sama
    # For proxying a zip, we can stream the original content; path handling is not possible via proxy
    target_url = f"http://127.0.0.1:8069/web/content/{attachment_id}/{path}"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(target_url)
            if resp.status_code == 200:
                # If the response is HTML we can inject; else pass-through
                ct = resp.headers.get('content-type', '')
                if 'html' in ct.lower():
                    injected = inject_shim_into_html(resp.content)
                    return Response(content=injected, media_type='text/html')
                return Response(
                    content=resp.content,
                    status_code=200,
                    media_type=ct or mimetype
                )
    except Exception as e:
        logger.error(f"[elearning/content] Proxy error for attachment {attachment_id}: {e}")

    # 4. Fallback: Generate SCORM zip / sample content jika file belum ada di server lokal
    raw_name = attachment.get("name") if attachment else path
    clean_title = raw_name.replace('.zip', '').replace('SCORM_', '').replace('_', ' ')
    sample_scorm_bytes = generate_sample_scorm_zip(clean_title)
    return Response(
        content=sample_scorm_bytes,
        status_code=200,
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{os.path.basename(path)}"'}
    )