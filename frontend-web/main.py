"""
Face Recognition Desktop Application
Built with PyQt6 — communicates with REST API only (no local ML model).
"""

import sys
import json
import os
import requests

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QFileDialog, QFrame, QProgressBar, QSizePolicy
)
from PyQt6.QtGui import QPixmap, QFont, QColor, QPalette
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QSize

# ──────────────────────────────────────────────────────────────────────────────
# Config loader
# ──────────────────────────────────────────────────────────────────────────────

def load_config() -> dict:
    """Load config.json from the same directory as this script."""
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"[WARN] config.json not found at {config_path}, using defaults.")
        return {"api_url": "http://localhost:8000/api"}
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid config.json: {e}")
        return {"api_url": "http://localhost:8000/api"}


CONFIG = load_config()
API_URL = CONFIG.get("api_url", "http://localhost:8000/api")

# ──────────────────────────────────────────────────────────────────────────────
# Worker thread — network request runs off the UI thread
# ──────────────────────────────────────────────────────────────────────────────

class RecognizeWorker(QThread):
    """Sends image to API in a background thread. Emits result or error signal."""

    result_ready = pyqtSignal(dict)
    error_occurred = pyqtSignal(str)

    def __init__(self, image_path: str, api_url: str):
        super().__init__()
        self.image_path = image_path
        self.api_url = api_url

    def run(self):
        try:
            with open(self.image_path, "rb") as img_file:
                files = {"image": (os.path.basename(self.image_path), img_file, "image/jpeg")}
                response = requests.post(
                    f"{self.api_url}/recognize",
                    files=files,
                    timeout=30
                )

            data = response.json()

            if response.status_code in (400, 500):
                error_msg = data.get("error", "Nieznany błąd serwera.")
                self.error_occurred.emit(error_msg)
                return

            self.result_ready.emit(data)

        except requests.exceptions.Timeout:
            self.error_occurred.emit("Przekroczono czas oczekiwania (30s). Sprawdź połączenie.")
        except requests.exceptions.ConnectionError:
            self.error_occurred.emit("Nie można połączyć z serwerem. Sprawdź adres w config.json.")
        except Exception as e:
            print(f"[ERROR] {e}")
            self.error_occurred.emit("Wystąpił nieoczekiwany błąd. Sprawdź konsolę.")


# ──────────────────────────────────────────────────────────────────────────────
# Main Window
# ──────────────────────────────────────────────────────────────────────────────

class MainWindow(QMainWindow):

    # ── Palette / colours ─────────────────────────────────────────────────────
    BG         = "#0a0a0f"
    SURFACE    = "#13131f"
    BORDER     = "#2a2a4a"
    ACCENT     = "#00e5ff"
    SUCCESS    = "#00ff88"
    DANGER     = "#ff2d55"
    WARNING    = "#ffd600"
    TEXT       = "#c8d0e0"
    TEXT_DIM   = "#5a6070"

    def __init__(self):
        super().__init__()
        self.setWindowTitle("System Rozpoznawania Twarzy")
        self.setMinimumSize(620, 700)
        self._selected_path: str | None = None
        self._worker: RecognizeWorker | None = None

        self._build_ui()
        self._apply_styles()

    # ── UI construction ────────────────────────────────────────────────────────

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(32, 28, 32, 28)
        root.setSpacing(0)

        # ── Header ──
        header = QVBoxLayout()
        header.setSpacing(4)

        badge = QLabel("▸ SYSTEM v1.0 ◂")
        badge.setAlignment(Qt.AlignmentFlag.AlignCenter)
        badge.setObjectName("badge")

        title = QLabel("ROZPOZNAWANIE TWARZY")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setObjectName("title")

        sub = QLabel("// facial recognition desktop client")
        sub.setAlignment(Qt.AlignmentFlag.AlignCenter)
        sub.setObjectName("subtitle")

        header.addWidget(badge)
        header.addWidget(title)
        header.addWidget(sub)
        root.addLayout(header)
        root.addSpacing(24)

        # ── Panel ──
        panel = QFrame()
        panel.setObjectName("panel")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(24, 24, 24, 24)
        panel_layout.setSpacing(16)

        # Section label
        lbl1 = QLabel("// 01 — wybierz zdjęcie")
        lbl1.setObjectName("section_label")
        panel_layout.addWidget(lbl1)

        # Image preview
        self.preview_label = QLabel()
        self.preview_label.setObjectName("preview")
        self.preview_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_label.setMinimumHeight(220)
        self.preview_label.setText("Brak wybranego zdjęcia")
        self.preview_label.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        panel_layout.addWidget(self.preview_label)

        # File info
        self.file_info_label = QLabel("")
        self.file_info_label.setObjectName("file_info")
        self.file_info_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        panel_layout.addWidget(self.file_info_label)

        # Choose file button
        self.choose_btn = QPushButton("📂  Wybierz plik")
        self.choose_btn.setObjectName("choose_btn")
        self.choose_btn.clicked.connect(self._choose_file)
        panel_layout.addWidget(self.choose_btn)

        # Divider
        divider = QFrame()
        divider.setFrameShape(QFrame.Shape.HLine)
        divider.setObjectName("divider")
        panel_layout.addWidget(divider)

        # Section label 2
        lbl2 = QLabel("// 02 — weryfikacja")
        lbl2.setObjectName("section_label")
        panel_layout.addWidget(lbl2)

        # Submit button
        self.submit_btn = QPushButton("▶  Sprawdź twarz")
        self.submit_btn.setObjectName("submit_btn")
        self.submit_btn.setEnabled(False)
        self.submit_btn.clicked.connect(self._run_recognition)
        panel_layout.addWidget(self.submit_btn)

        # Progress bar (hidden by default)
        self.progress = QProgressBar()
        self.progress.setObjectName("progress_bar")
        self.progress.setRange(0, 0)  # indeterminate
        self.progress.setVisible(False)
        self.progress.setMaximumHeight(4)
        panel_layout.addWidget(self.progress)

        # Result area
        self.result_frame = QFrame()
        self.result_frame.setObjectName("result_hidden")
        result_layout = QVBoxLayout(self.result_frame)
        result_layout.setContentsMargins(16, 14, 16, 14)
        result_layout.setSpacing(8)

        self.result_status = QLabel("")
        self.result_status.setObjectName("result_status")
        result_layout.addWidget(self.result_status)

        self.result_detail = QLabel("")
        self.result_detail.setObjectName("result_detail")
        self.result_detail.setWordWrap(True)
        result_layout.addWidget(self.result_detail)

        panel_layout.addWidget(self.result_frame)

        # API URL info
        api_info = QLabel(f"API: {API_URL}")
        api_info.setObjectName("api_info")
        api_info.setAlignment(Qt.AlignmentFlag.AlignRight)
        panel_layout.addWidget(api_info)

        root.addWidget(panel)

    # ── Styles ─────────────────────────────────────────────────────────────────

    def _apply_styles(self):
        self.setStyleSheet(f"""
            QMainWindow, QWidget {{
                background-color: {self.BG};
                font-family: 'Courier New', monospace;
            }}

            #badge {{
                color: {self.ACCENT};
                font-size: 10px;
                letter-spacing: 3px;
                opacity: 0.7;
            }}

            #title {{
                color: #ffffff;
                font-size: 22px;
                font-weight: bold;
                letter-spacing: 4px;
                font-family: 'Rajdhani', 'Segoe UI', sans-serif;
            }}

            #subtitle {{
                color: {self.TEXT_DIM};
                font-size: 11px;
                letter-spacing: 2px;
            }}

            #panel {{
                background-color: {self.SURFACE};
                border: 1px solid {self.BORDER};
                border-radius: 4px;
            }}

            #section_label {{
                color: {self.ACCENT};
                font-size: 10px;
                letter-spacing: 2px;
            }}

            #preview {{
                background-color: #0f0f1a;
                border: 1px dashed {self.BORDER};
                border-radius: 4px;
                color: {self.TEXT_DIM};
                font-size: 12px;
            }}

            #file_info {{
                color: {self.TEXT_DIM};
                font-size: 11px;
                letter-spacing: 1px;
            }}

            #choose_btn {{
                background: transparent;
                border: 1px solid {self.BORDER};
                color: {self.TEXT};
                font-family: 'Courier New', monospace;
                font-size: 12px;
                letter-spacing: 2px;
                padding: 10px;
                border-radius: 3px;
            }}

            #choose_btn:hover {{
                border-color: {self.ACCENT};
                color: {self.ACCENT};
            }}

            #divider {{
                color: {self.BORDER};
                background-color: {self.BORDER};
                max-height: 1px;
            }}

            #submit_btn {{
                background: transparent;
                border: 1px solid {self.ACCENT};
                color: {self.ACCENT};
                font-family: 'Courier New', monospace;
                font-size: 13px;
                letter-spacing: 3px;
                padding: 12px;
                border-radius: 3px;
            }}

            #submit_btn:hover:enabled {{
                background: {self.ACCENT};
                color: {self.BG};
            }}

            #submit_btn:disabled {{
                border-color: {self.BORDER};
                color: {self.TEXT_DIM};
                opacity: 0.4;
            }}

            #progress_bar {{
                border: none;
                background: {self.BORDER};
            }}

            #progress_bar::chunk {{
                background: {self.ACCENT};
            }}

            #result_hidden {{
                border: 1px solid {self.BORDER};
                border-radius: 4px;
                background: transparent;
            }}

            #result_success {{
                border: 1px solid {self.SUCCESS};
                border-radius: 4px;
                background: rgba(0,255,136,0.07);
            }}

            #result_failure {{
                border: 1px solid {self.DANGER};
                border-radius: 4px;
                background: rgba(255,45,85,0.07);
            }}

            #result_error {{
                border: 1px solid {self.WARNING};
                border-radius: 4px;
                background: rgba(255,214,0,0.07);
            }}

            #result_status {{
                font-size: 12px;
                font-weight: bold;
                letter-spacing: 2px;
            }}

            #result_detail {{
                font-size: 12px;
                color: {self.TEXT};
            }}

            #api_info {{
                color: {self.TEXT_DIM};
                font-size: 10px;
                letter-spacing: 1px;
            }}
        """)

    # ── Logic ──────────────────────────────────────────────────────────────────

    def _choose_file(self):
        path, _ = QFileDialog.getOpenFileName(
            self,
            "Wybierz zdjęcie",
            "",
            "Obrazy (*.jpg *.jpeg *.png)"
        )
        if not path:
            return

        self._selected_path = path
        self._show_preview(path)
        self.submit_btn.setEnabled(True)
        self._clear_result()

        file_size = os.path.getsize(path)
        self.file_info_label.setText(f"{os.path.basename(path)}  ({file_size // 1024} KB)")

    def _show_preview(self, path: str):
        pixmap = QPixmap(path)
        if pixmap.isNull():
            self.preview_label.setText("Nie można wyświetlić podglądu.")
            return
        scaled = pixmap.scaled(
            QSize(560, 280),
            Qt.AspectRatioMode.KeepAspectRatio,
            Qt.TransformationMode.SmoothTransformation
        )
        self.preview_label.setPixmap(scaled)

    def _run_recognition(self):
        if not self._selected_path:
            return

        self.submit_btn.setEnabled(False)
        self.choose_btn.setEnabled(False)
        self.progress.setVisible(True)
        self._clear_result()

        self._worker = RecognizeWorker(self._selected_path, API_URL)
        self._worker.result_ready.connect(self._on_result)
        self._worker.error_occurred.connect(self._on_error)
        self._worker.start()

    def _on_result(self, data: dict):
        self._stop_loading()

        if data.get("matched"):
            person = data.get("person", "Nieznana osoba")
            confidence = data.get("confidence", 0.0)
            pct = int(confidence * 100)
            self.result_frame.setObjectName("result_success")
            self.result_frame.setStyleSheet(self.styleSheet())
            self.result_status.setText("✅  TWARZ ROZPOZNANA")
            self.result_status.setStyleSheet(f"color: #00ff88; font-size: 12px; letter-spacing: 2px;")
            self.result_detail.setText(f"Osoba:   {person}\nPewność: {pct}%")
        else:
            self.result_frame.setObjectName("result_failure")
            self.result_frame.setStyleSheet(self.styleSheet())
            self.result_status.setText("❌  NIE ROZPOZNANO")
            self.result_status.setStyleSheet(f"color: #ff2d55; font-size: 12px; letter-spacing: 2px;")
            self.result_detail.setText("Osoba nieznana w bazie danych.")

        self._refresh_frame_style()

    def _on_error(self, message: str):
        self._stop_loading()
        self.result_frame.setObjectName("result_error")
        self.result_status.setText("⚠️  BŁĄD")
        self.result_status.setStyleSheet(f"color: #ffd600; font-size: 12px; letter-spacing: 2px;")
        self.result_detail.setText(message)
        self._refresh_frame_style()

    def _stop_loading(self):
        self.progress.setVisible(False)
        self.submit_btn.setEnabled(True)
        self.choose_btn.setEnabled(True)

    def _clear_result(self):
        self.result_frame.setObjectName("result_hidden")
        self.result_status.setText("")
        self.result_detail.setText("")
        self._refresh_frame_style()

    def _refresh_frame_style(self):
        """Force Qt to re-apply stylesheet after objectName change."""
        self.result_frame.style().unpolish(self.result_frame)
        self.result_frame.style().polish(self.result_frame)
        self.result_frame.update()


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    # Dark palette base
    palette = QPalette()
    palette.setColor(QPalette.ColorRole.Window, QColor("#0a0a0f"))
    palette.setColor(QPalette.ColorRole.WindowText, QColor("#c8d0e0"))
    palette.setColor(QPalette.ColorRole.Base, QColor("#13131f"))
    palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#0f0f1a"))
    palette.setColor(QPalette.ColorRole.ToolTipBase, QColor("#0a0a0f"))
    palette.setColor(QPalette.ColorRole.ToolTipText, QColor("#c8d0e0"))
    palette.setColor(QPalette.ColorRole.Text, QColor("#c8d0e0"))
    palette.setColor(QPalette.ColorRole.Button, QColor("#13131f"))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor("#c8d0e0"))
    palette.setColor(QPalette.ColorRole.Highlight, QColor("#00e5ff"))
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor("#0a0a0f"))
    app.setPalette(palette)

    window = MainWindow()
    window.show()
    sys.exit(app.exec())
