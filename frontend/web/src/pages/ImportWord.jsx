import {
  useContext,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  useNavigate,
} from "react-router-dom";
import * as mammoth from "mammoth";
import {
  FaAlignLeft,
  FaArrowLeft,
  FaArrowRight,
  FaCalculator,
  FaCalendarAlt,
  FaCheck,
  FaCheckCircle,
  FaCircle,
  FaClock,
  FaCode,
  FaCog,
  FaCopy,
  FaEye,
  FaEyeSlash,
  FaFileAlt,
  FaFileWord,
  FaFont,
  FaGlobe,
  FaHourglassHalf,
  FaInfoCircle,
  FaLink,
  FaListUl,
  FaLock,
  FaMinus,
  FaPlus,
  FaPowerOff,
  FaQrcode,
  FaQuestionCircle,
  FaRandom,
  FaStar,
  FaTimes,
  FaTrash,
  FaTrophy,
  FaUpload,
} from "react-icons/fa";
import {
  ThemeContext,
} from "../context/ThemeContext";

const importWordStyles = `
/* === ImportWord.css === */
/* =========================================================
   IMPORT WORD PAGE
========================================================= */
.import-word-page {
  min-height: 100vh;
  background: linear-gradient( 180deg, #f7f9fc 0%, #f4f7fb 100% );
  color: #1f2a44;
  font-family: "Poppins", sans-serif;
  padding-bottom: 70px;
}
.import-word-page * {
  box-sizing: border-box;
}
/* =========================================================
   DARK MODE
========================================================= */
.import-word-page.dark {
  background: linear-gradient( 180deg, #111827 0%, #0f172a 100% );
  color: #e5e7eb;
}
/* =========================================================
   HEADER
========================================================= */
.import-word-header {
  min-height: 94px;
  padding: 22px clamp(22px, 5vw, 72px);
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 20px;
  position: sticky;
  top: 0;
  z-index: 40;
  background: rgba( 255, 255, 255, 0.94 );
  border-bottom: 1px solid #e8edf4;
  backdrop-filter: blur(20px);
}
.import-word-page.dark
.import-word-header {
  background: rgba( 17, 24, 39, 0.94 );
  border-bottom-color: #273449;
}
/* =========================================================
   BACK BUTTON
========================================================= */
.import-back-btn {
  width: 44px;
  height: 44px;
  border: none;
  border-radius: 14px;
  background: #eef4ff;
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 19px;
  transition: 0.2s ease;
}
.import-back-btn:hover {
  transform: translateX( -2px );
  background: #e0ebff;
}
.import-word-page.dark
.import-back-btn {
  background: #1e293b;
  color: #7da8ff;
}
/* =========================================================
   HEADER TITLE
========================================================= */
.import-header-title {
  min-width: 0;
}
.import-header-title > span {
  display: block;
  font-size: 14px;
  font-weight: 700;
  color: #718096;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  margin-bottom: 4px;
}
.import-header-title h1 {
  margin: 0;
  font-size: clamp( 22px, 2vw, 28px );
  line-height: 1.15;
  color: #183153;
  font-weight: 800;
}
.import-word-page.dark
.import-header-title h1 {
  color: #f8fafc;
}
.import-word-page.dark
.import-header-title > span {
  color: #94a3b8;
}
/* =========================================================
   HEADER ACTIONS
========================================================= */
.import-header-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}
.import-previous-btn,
.import-save-btn {
  min-height: 44px;
  border: none;
  border-radius: 13px;
  padding: 0 20px;
  font-family: inherit;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  transition: transform 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}
.import-previous-btn {
  background: #f1f4f9;
  color: #45536c;
}
.import-previous-btn:hover {
  background: #e7ecf3;
}
.import-save-btn {
  background: linear-gradient( 135deg, #2563eb, #397cf6 );
  color: #ffffff;
  box-shadow: 0 10px 24px rgba( 37, 99, 235, 0.22 );
}
.import-save-btn:hover:not(:disabled) {
  transform: translateY( -1px );
  box-shadow: 0 14px 30px rgba( 37, 99, 235, 0.3 );
}
.import-save-btn:disabled {
  opacity: 0.48;
  cursor: not-allowed;
  box-shadow: none;
}
.import-word-page.dark
.import-previous-btn {
  background: #1f2937;
  color: #d6deea;
}
/* =========================================================
   TABS
========================================================= */
.import-tabs {
  width: min( 1180px, calc( 100% - 40px ) );
  margin: 24px auto 0;
  display: grid;
  grid-template-columns: repeat( 4, 1fr );
  background: #ffffff;
  padding: 8px;
  border: 1px solid #e6ebf2;
  border-radius: 20px;
  box-shadow: 0 10px 35px rgba( 34, 58, 86, 0.06 );
  gap: 6px;
}
.import-tab {
  min-height: 58px;
  border: none;
  border-radius: 14px;
  background: transparent;
  color: #748197;
  font-family: inherit;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  transition: 0.2s ease;
}
.import-tab svg {
  font-size: 17px;
}
.import-tab:hover {
  background: #f6f9fe;
  color: #315a9f;
}
.import-tab.active {
  background: linear-gradient( 135deg, #edf4ff, #f4f8ff );
  color: #2563eb;
  box-shadow: inset 0 0 0 1px #d5e4ff;
}
.import-tab-number {
  width: 27px;
  height: 27px;
  border-radius: 50%;
  background: #eef1f5;
  color: #7f8ba0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 800;
}
.import-tab.active
.import-tab-number {
  background: #2563eb;
  color: #ffffff;
}
.import-word-page.dark
.import-tabs {
  background: #151f2f;
  border-color: #273449;
}
.import-word-page.dark
.import-tab {
  color: #9ca9bc;
}
.import-word-page.dark
.import-tab:hover {
  background: #1a283a;
  color: #bfd2ff;
}
.import-word-page.dark
.import-tab.active {
  background: #1d2d44;
  color: #83aaff;
  box-shadow: inset 0 0 0 1px #31517c;
}
.import-word-page.dark
.import-tab-number {
  background: #283447;
  color: #adbacb;
}
/* =========================================================
   STATUS BAR
========================================================= */
.import-status-bar {
  width: min( 1180px, calc( 100% - 40px ) );
  margin: 14px auto 0;
  padding: 13px 18px;
  border-radius: 15px;
  background: #edf5ff;
  color: #30568e;
  border: 1px solid #d9e9ff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  font-size: 15px;
}
.import-status-bar > div {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}
.import-status-bar > div:first-child span {
  max-width: 360px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 600;
}
.import-status-bar > div:last-child {
  flex-wrap: wrap;
  justify-content: flex-end;
}
.import-status-bar strong {
  color: #1d4ed8;
  margin-left: 7px;
}
.import-word-page.dark
.import-status-bar {
  background: #17273d;
  color: #a9c6ef;
  border-color: #294564;
}
.import-word-page.dark
.import-status-bar strong {
  color: #8bb4ff;
}
/* =========================================================
   MAIN CONTENT
========================================================= */
.import-word-content,
.import-settings-page {
  width: min( 1180px, calc( 100% - 40px ) );
  margin: 24px auto 0;
}
.import-word-content {
  display: flex;
  flex-direction: column;
  gap: 22px;
}
.import-settings-page {
  display: grid;
  grid-template-columns: repeat( 2, minmax( 0, 1fr ) );
  gap: 22px;
  align-items: start;
}
/* =========================================================
   SECTION CARD
========================================================= */
.import-word-section {
  background: #ffffff;
  border: 1px solid #e7ebf1;
  border-radius: 24px;
  padding: clamp( 22px, 3vw, 32px );
  box-shadow: 0 14px 45px rgba( 34, 58, 86, 0.06 );
}
.import-word-page.dark
.import-word-section {
  background: #151f2f;
  border-color: #273449;
  box-shadow: 0 18px 45px rgba( 0, 0, 0, 0.15 );
}
/* =========================================================
   SECTION HEADING
========================================================= */
.import-section-heading {
  display: flex;
  align-items: flex-start;
  gap: 15px;
  margin-bottom: 26px;
}
.import-section-icon {
  width: 46px;
  height: 46px;
  min-width: 46px;
  border-radius: 15px;
  background: linear-gradient( 135deg, #e9f2ff, #f2f6ff );
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 21px;
}
.import-section-heading > div:last-child {
  min-width: 0;
}
.import-section-heading span {
  display: block;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.08em;
  color: #758399;
  text-transform: uppercase;
  margin-bottom: 3px;
}
.import-section-heading h2 {
  margin: 0;
  color: #21334f;
  font-size: 22px;
  line-height: 1.25;
  font-weight: 800;
}
.import-section-heading p {
  margin: 7px 0 0;
  font-size: 15px;
  line-height: 1.65;
  color: #758197;
}
.import-word-page.dark
.import-section-icon {
  background: #1f3655;
  color: #83adff;
}
.import-word-page.dark
.import-section-heading h2 {
  color: #f1f5f9;
}
.import-word-page.dark
.import-section-heading span,
.import-word-page.dark
.import-section-heading p {
  color: #93a4b9;
}
/* =========================================================
   UPLOAD DROP ZONE
========================================================= */
.import-drop-zone {
  min-height: 330px;
  border: 2px dashed #c7d9f2;
  border-radius: 24px;
  padding: 42px 24px;
  background: linear-gradient( 180deg, #fbfdff, #f5f9ff );
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  cursor: pointer;
  transition: 0.25s ease;
}
.import-drop-zone:hover {
  border-color: #7aa8ee;
  background: #f0f6ff;
  transform: translateY( -1px );
}
.import-drop-icon {
  width: 80px;
  height: 80px;
  border-radius: 24px;
  background: linear-gradient( 135deg, #e3efff, #eef5ff );
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 38px;
  margin-bottom: 18px;
  box-shadow: 0 14px 28px rgba( 37, 99, 235, 0.1 );
}
.import-drop-zone h3 {
  margin: 0 0 8px;
  font-size: 22px;
  color: #233753;
}
.import-drop-zone p {
  margin: 0 0 19px;
  color: #78869a;
  font-size: 16px;
  max-width: 520px;
  line-height: 1.6;
}
.import-drop-zone button {
  min-height: 45px;
  padding: 0 21px;
  border: none;
  border-radius: 13px;
  background: #2563eb;
  color: #ffffff;
  display: inline-flex;
  align-items: center;
  gap: 9px;
  font-family: inherit;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 9px 22px rgba( 37, 99, 235, 0.24 );
}
.import-drop-zone small {
  margin-top: 15px;
  color: #99a3b3;
  font-size: 13px;
  font-weight: 600;
}
.import-word-page.dark
.import-drop-zone {
  background: #111b29;
  border-color: #34506f;
}
.import-word-page.dark
.import-drop-zone:hover {
  background: #152238;
  border-color: #5583bd;
}
.import-word-page.dark
.import-drop-zone h3 {
  color: #f2f6fb;
}
.import-word-page.dark
.import-drop-zone p,
.import-word-page.dark
.import-drop-zone small {
  color: #93a4b9;
}
/* =========================================================
   SELECTED FILE
========================================================= */
.import-selected-file {
  display: grid;
  grid-template-columns: auto minmax( 0, 1fr ) auto auto;
  align-items: center;
  gap: 18px;
  padding: 20px;
  border: 1px solid #dfe8f5;
  background: #f8fbff;
  border-radius: 18px;
}
.import-selected-file-icon {
  width: 56px;
  height: 56px;
  border-radius: 17px;
  background: #e8f2ff;
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 27px;
}
.import-selected-file-info {
  min-width: 0;
}
.import-selected-file-info span,
.import-selected-file-info small {
  display: block;
}
.import-selected-file-info span {
  color: #8290a5;
  font-size: 13px;
  font-weight: 700;
  margin-bottom: 3px;
}
.import-selected-file-info strong {
  display: block;
  color: #263851;
  font-size: 16px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.import-selected-file-info small {
  margin-top: 3px;
  color: #9aa5b4;
  font-size: 13px;
}
.import-selected-file-result {
  padding: 10px 15px;
  border-radius: 13px;
  background: #eaf8ef;
  color: #278455;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  font-size: 13px;
}
.import-selected-file-result svg {
  margin-bottom: 2px;
}
.import-selected-file-result strong {
  font-size: 15px;
}
.import-remove-file {
  width: 39px;
  height: 39px;
  border: none;
  border-radius: 12px;
  color: #e04a4a;
  background: #fff0f0;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.import-remove-file:hover {
  background: #ffe1e1;
}
.import-word-page.dark
.import-selected-file {
  background: #111c2a;
  border-color: #2b3d53;
}
.import-word-page.dark
.import-selected-file-info strong {
  color: #ecf2f9;
}
.import-word-page.dark
.import-selected-file-info span,
.import-word-page.dark
.import-selected-file-info small {
  color: #98a9bd;
}
.import-word-page.dark
.import-selected-file-result {
  background: #153729;
  color: #85d6aa;
}
.import-word-page.dark
.import-remove-file {
  background: #3c2027;
  color: #ff9090;
}
/* =========================================================
   PROCESSING + MESSAGE
========================================================= */
.import-processing,
.import-message {
  margin-top: 17px;
  border-radius: 15px;
  padding: 14px 16px;
  display: flex;
  gap: 12px;
  align-items: center;
}
.import-processing {
  background: #f1f6ff;
  color: #41628f;
}
.import-processing strong,
.import-processing p {
  display: block;
}
.import-processing p {
  margin: 3px 0 0;
  font-size: 14px;
}
.import-spinner {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  border: 3px solid rgba( 37, 99, 235, 0.2 );
  border-top-color: #2563eb;
  animation: importSpinner 0.85s linear infinite;
}
@keyframes importSpinner {
  to {
    transform: rotate( 360deg );
  }
}
.import-message {
  font-size: 15px;
  font-weight: 600;
}
.import-message.success {
  background: #eaf8ef;
  color: #247b50;
}
.import-message.error {
  background: #fff0f0;
  color: #c94646;
}
.import-word-page.dark
.import-processing {
  background: #17263b;
  color: #a8c1e2;
}
.import-word-page.dark
.import-message.success {
  background: #153629;
  color: #91d9b2;
}
.import-word-page.dark
.import-message.error {
  background: #3e2229;
  color: #ff9d9d;
}
/* =========================================================
   TEMPLATE GUIDE
========================================================= */
.template-guide {
  overflow: hidden;
}
.import-template-example {
  border-radius: 18px;
  overflow: auto;
  background: #132238;
  border: 1px solid #1e3556;
}
.import-template-example pre {
  margin: 0;
  padding: 22px;
  color: #d9e9ff;
  font-family: "Consolas", "Courier New", monospace;
  font-size: 14px;
  line-height: 1.75;
  white-space: pre-wrap;
  word-break: break-word;
}
.import-template-note {
  margin: 15px 0 0;
  color: #748197;
  font-size: 14px;
  line-height: 1.7;
}
.import-word-page.dark
.import-template-note {
  color: #93a4b9;
}
/* =========================================================
   INPUT FIELD
========================================================= */
.import-field {
  margin-bottom: 20px;
}
.import-field:last-child {
  margin-bottom: 0;
}
.import-field label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  color: #536178;
  font-weight: 700;
}
.import-field > small {
  display: block;
  margin-top: 7px;
  font-size: 13px;
  color: #8d98aa;
}
.import-input-wrapper {
  min-height: 49px;
  border: 1px solid #dce3ed;
  border-radius: 14px;
  background: #fbfcfe;
  display: flex;
  align-items: center;
  overflow: hidden;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}
.import-input-wrapper:focus-within {
  border-color: #84aef2;
  box-shadow: 0 0 0 4px rgba( 37, 99, 235, 0.08 );
}
.import-input-wrapper > svg {
  margin-left: 15px;
  min-width: 17px;
  color: #8695aa;
}
.import-input-wrapper input {
  flex: 1;
  min-width: 0;
  height: 47px;
  border: none;
  outline: none;
  background: transparent;
  padding: 0 14px;
  color: #253550;
  font-family: inherit;
  font-size: 15px;
}
.import-field textarea,
.import-field select,
.import-field > input {
  width: 100%;
  min-height: 48px;
  border: 1px solid #dce3ed;
  border-radius: 14px;
  background: #fbfcfe;
  padding: 12px 14px;
  outline: none;
  color: #253550;
  font-family: inherit;
  font-size: 15px;
  transition: 0.2s ease;
}
.import-field textarea {
  resize: vertical;
  line-height: 1.65;
}
.import-field textarea:focus,
.import-field select:focus,
.import-field > input:focus {
  border-color: #84aef2;
  box-shadow: 0 0 0 4px rgba( 37, 99, 235, 0.08 );
}
.import-random-link-btn {
  width: 48px;
  height: 48px;
  min-width: 48px;
  border: none;
  border-left: 1px solid #e2e8f0;
  background: #f3f7fd;
  color: #2563eb;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.import-random-link-btn:hover {
  background: #eaf2ff;
}
.import-word-page.dark
.import-field label {
  color: #b4c0cf;
}
.import-word-page.dark
.import-field > small {
  color: #8192a7;
}
.import-word-page.dark
.import-input-wrapper,
.import-word-page.dark
.import-field textarea,
.import-word-page.dark
.import-field select,
.import-word-page.dark
.import-field > input {
  background: #111b29;
  border-color: #304056;
  color: #ecf2f8;
}
.import-word-page.dark
.import-input-wrapper input {
  color: #ecf2f8;
}
.import-word-page.dark
.import-input-wrapper > svg {
  color: #8fa5c0;
}
.import-word-page.dark
.import-random-link-btn {
  background: #1c2b40;
  border-left-color: #304056;
  color: #87adff;
}
/* =========================================================
   SCHEDULE GRID
========================================================= */
.import-schedule-grid {
  display: grid;
  grid-template-columns: repeat( 2, minmax( 0, 1fr ) );
  gap: 3px 18px;
}
/* =========================================================
   SETTINGS TOGGLE
========================================================= */
.import-setting-option {
  display: grid;
  grid-template-columns: auto minmax( 0, 1fr ) auto auto;
  align-items: center;
  gap: 14px;
  min-height: 82px;
  padding: 15px 16px;
  border: 1px solid #e4e9f1;
  border-radius: 17px;
  margin-bottom: 12px;
  cursor: pointer;
  background: #fbfcfe;
  transition: 0.2s ease;
}
.import-setting-option:hover {
  border-color: #c7d8f0;
  background: #f7faff;
}
.import-setting-icon {
  width: 42px;
  height: 42px;
  border-radius: 13px;
  background: #eaf2ff;
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}
.import-setting-content {
  min-width: 0;
}
.import-setting-content strong,
.import-setting-content span {
  display: block;
}
.import-setting-content strong {
  color: #2b3a52;
  font-size: 15px;
  margin-bottom: 4px;
}
.import-setting-content span {
  color: #8490a2;
  font-size: 13px;
  line-height: 1.5;
}
.import-setting-option > input {
  position: absolute;
  opacity: 0;
  pointer-events: none;
}
.import-toggle {
  width: 45px;
  height: 25px;
  border-radius: 999px;
  background: #ced5de;
  padding: 3px;
  display: inline-flex;
  align-items: center;
  transition: 0.2s ease;
}
.import-toggle span {
  width: 19px;
  height: 19px;
  border-radius: 50%;
  background: #ffffff;
  box-shadow: 0 2px 5px rgba( 0, 0, 0, 0.15 );
  transition: 0.2s ease;
}
.import-setting-option
> input:checked
+ .import-toggle {
  background: #2563eb;
}
.import-setting-option
> input:checked
+ .import-toggle
span {
  transform: translateX( 20px );
}
.import-word-page.dark
.import-setting-option {
  background: #111b29;
  border-color: #2e3f56;
}
.import-word-page.dark
.import-setting-option:hover {
  background: #172438;
}
.import-word-page.dark
.import-setting-content strong {
  color: #edf3fa;
}
.import-word-page.dark
.import-setting-content span {
  color: #95a6ba;
}
.import-word-page.dark
.import-setting-icon {
  background: #1d3350;
  color: #87aeff;
}
/* =========================================================
   TIMER CARD
========================================================= */
.import-timer-card {
  min-height: 77px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 15px 17px;
  border: 1px solid #e5eaf1;
  border-radius: 17px;
  margin-top: 12px;
  background: #f9fbfe;
}
.import-timer-card > div:first-child {
  min-width: 0;
}
.import-timer-card strong,
.import-timer-card span {
  display: block;
}
.import-timer-card strong {
  color: #2b3c55;
  font-size: 15px;
  margin-bottom: 4px;
}
.import-timer-card > div:first-child > span {
  color: #8692a4;
  font-size: 13px;
}
.import-timer-input {
  display: flex;
  align-items: center;
  gap: 8px;
}
.import-timer-input input {
  width: 85px;
  height: 42px;
  border: 1px solid #d7dfe9;
  border-radius: 12px;
  padding: 0 10px;
  font-family: inherit;
  outline: none;
}
.import-timer-input span {
  color: #768297;
  font-size: 13px;
}
.import-timer-card > select {
  min-width: 115px;
  height: 42px;
  border: 1px solid #d7dfe9;
  border-radius: 12px;
  background: #ffffff;
  padding: 0 11px;
  font-family: inherit;
  color: #394a64;
  outline: none;
}
.import-word-page.dark
.import-timer-card {
  background: #111b29;
  border-color: #2f4057;
}
.import-word-page.dark
.import-timer-card strong {
  color: #edf3fa;
}
.import-word-page.dark
.import-timer-card > div:first-child > span,
.import-word-page.dark
.import-timer-input span {
  color: #93a4b9;
}
.import-word-page.dark
.import-timer-input input,
.import-word-page.dark
.import-timer-card > select {
  background: #162233;
  border-color: #33465f;
  color: #e6edf7;
}
/* =========================================================
   CHOICE CARD
========================================================= */
.import-radio-grid {
  display: grid;
  grid-template-columns: repeat( 2, minmax( 0, 1fr ) );
  gap: 14px;
}
.import-choice-card {
  position: relative;
  min-height: 145px;
  border: 1px solid #e0e7f0;
  border-radius: 19px;
  padding: 20px;
  display: flex;
  align-items: flex-start;
  gap: 14px;
  background: #fbfcfe;
  cursor: pointer;
  transition: 0.2s ease;
}
.import-choice-card:hover {
  border-color: #c6d8f3;
  transform: translateY( -1px );
}
.import-choice-card.selected {
  border-color: #75a7f1;
  background: #f0f6ff;
  box-shadow: 0 0 0 3px rgba( 37, 99, 235, 0.06 );
}
.import-choice-card > svg {
  min-width: 37px;
  min-height: 37px;
  padding: 9px;
  border-radius: 12px;
  background: #e9f2ff;
  color: #2563eb;
}
.import-choice-card strong,
.import-choice-card span {
  display: block;
}
.import-choice-card strong {
  color: #293a52;
  font-size: 15px;
  margin-bottom: 6px;
}
.import-choice-card span {
  color: #7f8b9e;
  font-size: 13px;
  line-height: 1.6;
}
.import-choice-card input {
  position: absolute;
  right: 15px;
  top: 15px;
  accent-color: #2563eb;
}
.import-word-page.dark
.import-choice-card {
  background: #111b29;
  border-color: #304056;
}
.import-word-page.dark
.import-choice-card.selected {
  background: #172941;
  border-color: #4678bf;
}
.import-word-page.dark
.import-choice-card strong {
  color: #edf3fa;
}
.import-word-page.dark
.import-choice-card span {
  color: #95a6ba;
}
/* =========================================================
   RESULT OPTIONS
========================================================= */
.import-result-options {
  display: flex;
  flex-direction: column;
  gap: 11px;
}
.import-result-option {
  position: relative;
  min-height: 77px;
  padding: 14px 16px;
  border: 1px solid #e1e7ef;
  border-radius: 17px;
  display: grid;
  grid-template-columns: auto minmax( 0, 1fr ) auto;
  align-items: center;
  gap: 13px;
  background: #fbfcfe;
  cursor: pointer;
  transition: 0.2s ease;
}
.import-result-option:hover {
  border-color: #c9d9f0;
}
.import-result-option.selected {
  border-color: #7caaf0;
  background: #f1f6ff;
}
.import-result-icon {
  width: 42px;
  height: 42px;
  border-radius: 13px;
  background: #eaf2ff;
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
}
.import-result-option strong,
.import-result-option span {
  display: block;
}
.import-result-option strong {
  color: #2b3b52;
  font-size: 15px;
  margin-bottom: 4px;
}
.import-result-option span {
  color: #8490a2;
  font-size: 13px;
  line-height: 1.5;
}
.import-result-option input {
  accent-color: #2563eb;
}
.import-word-page.dark
.import-result-option {
  background: #111b29;
  border-color: #304056;
}
.import-word-page.dark
.import-result-option.selected {
  background: #172941;
  border-color: #497bc1;
}
.import-word-page.dark
.import-result-option strong {
  color: #edf3fa;
}
.import-word-page.dark
.import-result-option span {
  color: #95a6ba;
}
/* =========================================================
   QUESTION SUMMARY
========================================================= */
.import-question-summary {
  min-height: 128px;
  border-radius: 23px;
  padding: 26px 30px;
  background: linear-gradient( 135deg, #1f5ec8, #3279ee );
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 25px;
  overflow: hidden;
  position: relative;
}
.import-question-summary > div:first-child {
  min-width: 0;
}
.import-question-summary > div:first-child > span {
  display: block;
  font-size: 13px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-weight: 800;
  opacity: 0.82;
}
.import-question-summary h2 {
  margin: 5px 0 5px;
  font-size: 25px;
  line-height: 1.25;
}
.import-question-summary p {
  margin: 0;
  font-size: 14px;
  opacity: 0.88;
}
.import-question-total {
  min-width: 105px;
  min-height: 82px;
  border-radius: 18px;
  background: rgba( 255, 255, 255, 0.15 );
  border: 1px solid rgba( 255, 255, 255, 0.22 );
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.import-question-total strong {
  font-size: 31px;
  line-height: 1;
}
.import-question-total span {
  font-size: 13px;
  margin-top: 5px;
}
/* =========================================================
   QUESTION LIST
========================================================= */
.import-question-list {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.import-question-card {
  background: #ffffff;
  border: 1px solid #e5e9ef;
  border-radius: 23px;
  padding: 23px;
  box-shadow: 0 12px 35px rgba( 35, 60, 90, 0.05 );
}
.import-word-page.dark
.import-question-card {
  background: #151f2f;
  border-color: #2b3a50;
}
/* =========================================================
   QUESTION HEADER
========================================================= */
.import-question-header {
  display: grid;
  grid-template-columns: auto minmax( 0, 1fr ) auto;
  gap: 12px;
  align-items: center;
  margin-bottom: 21px;
}
.import-question-number {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  background: #2563eb;
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15px;
  font-weight: 800;
}
.import-question-type {
  display: flex;
  align-items: center;
  gap: 9px;
  min-width: 0;
  color: #425674;
}
.import-question-type svg {
  color: #2563eb;
}
.import-question-type span {
  font-size: 14px;
  font-weight: 700;
}
.import-question-actions {
  display: flex;
  gap: 7px;
}
.import-question-actions button {
  width: 37px;
  height: 37px;
  border: none;
  border-radius: 11px;
  background: #f1f4f8;
  color: #56657b;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.import-question-actions button:hover {
  background: #e8edf4;
}
.import-question-actions button.danger {
  background: #fff0f0;
  color: #d94b4b;
}
.import-question-actions button.danger:hover {
  background: #ffe2e2;
}
.import-word-page.dark
.import-question-type {
  color: #b7c3d3;
}
.import-word-page.dark
.import-question-actions button {
  background: #202d3f;
  color: #aebbc9;
}
.import-word-page.dark
.import-question-actions button.danger {
  background: #40252c;
  color: #ff9797;
}
/* =========================================================
   OPTIONS
========================================================= */
.import-options-section {
  margin-top: 20px;
}
.import-options-section > label {
  display: block;
  color: #58667c;
  font-size: 14px;
  font-weight: 700;
  margin-bottom: 10px;
}
.import-option-row {
  display: grid;
  grid-template-columns: 34px minmax( 0, 1fr ) auto;
  gap: 9px;
  align-items: center;
  margin-bottom: 9px;
}
.import-option-row > span {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: #edf4ff;
  color: #2563eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 800;
}
.import-option-row input {
  width: 100%;
  min-height: 42px;
  border: 1px solid #dce3eb;
  border-radius: 12px;
  padding: 0 13px;
  font-family: inherit;
  font-size: 14px;
  outline: none;
  background: #fbfcfe;
  color: #2b3b52;
}
.import-option-row input:focus {
  border-color: #8ab0ed;
  box-shadow: 0 0 0 3px rgba( 37, 99, 235, 0.07 );
}
.import-option-row button {
  width: 37px;
  height: 37px;
  border: none;
  border-radius: 10px;
  background: #fff0f0;
  color: #d54e4e;
  cursor: pointer;
}
.import-add-option {
  margin-top: 5px;
  min-height: 38px;
  padding: 0 14px;
  border: 1px dashed #a9c3e7;
  border-radius: 11px;
  background: #f6f9ff;
  color: #2563eb;
  font-family: inherit;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 7px;
}
.import-word-page.dark
.import-options-section > label {
  color: #b4c0cf;
}
.import-word-page.dark
.import-option-row > span {
  background: #1e3451;
  color: #8aafff;
}
.import-word-page.dark
.import-option-row input {
  background: #111b29;
  border-color: #304056;
  color: #e8eef6;
}
.import-word-page.dark
.import-add-option {
  background: #17263a;
  border-color: #41648d;
  color: #8db1ff;
}
/* =========================================================
   YES NO + RATING PREVIEW
========================================================= */
.import-yesno-preview,
.import-rating-preview {
  margin-top: 17px;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.import-yesno-preview span,
.import-rating-preview span {
  min-height: 39px;
  padding: 0 14px;
  border-radius: 11px;
  background: #f3f7fc;
  color: #55657c;
  display: inline-flex;
  align-items: center;
  gap: 7px;
  font-size: 13px;
  font-weight: 600;
}
.import-rating-preview svg {
  color: #f2aa25;
}
.import-word-page.dark
.import-yesno-preview span,
.import-word-page.dark
.import-rating-preview span {
  background: #1b293b;
  color: #b5c1cf;
}
/* =========================================================
   QUESTION SETTINGS
========================================================= */
.import-question-settings {
  margin-top: 21px;
  padding-top: 17px;
  border-top: 1px solid #ebeff4;
  display: flex;
  gap: 19px;
  flex-wrap: wrap;
}
.import-inline-toggle {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #5b697e;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}
.import-inline-toggle input {
  accent-color: #2563eb;
}
.import-word-page.dark
.import-question-settings {
  border-top-color: #2b394e;
}
.import-word-page.dark
.import-inline-toggle {
  color: #b0bdcc;
}
/* =========================================================
   SCORE SETTINGS
========================================================= */
.import-score-settings {
  margin-top: 17px;
  padding: 17px;
  border-radius: 16px;
  background: #f6f9fe;
  border: 1px solid #e1e9f4;
  display: grid;
  grid-template-columns: minmax( 130px, 0.3fr ) minmax( 0, 1fr );
  gap: 15px;
}
.import-score-settings
.import-field {
  margin: 0;
}
.import-word-page.dark
.import-score-settings {
  background: #111b29;
  border-color: #2f4057;
}
/* =========================================================
   ADD QUESTION BUTTON
========================================================= */
.import-add-question-btn {
  width: 100%;
  min-height: 54px;
  border: 1px dashed #a8c2e7;
  border-radius: 17px;
  background: #f5f9ff;
  color: #2563eb;
  font-family: inherit;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  transition: 0.2s ease;
}
.import-add-question-btn:hover {
  background: #ebf3ff;
  border-color: #7da8e9;
}
.import-word-page.dark
.import-add-question-btn {
  background: #17263b;
  color: #8eb3ff;
  border-color: #41648f;
}
/* =========================================================
   GENERIC DISABLED
========================================================= */
.import-word-page input:disabled,
.import-word-page select:disabled,
.import-word-page textarea:disabled,
.import-word-page button:disabled {
  cursor: not-allowed;
}
/* =========================================================
   SCROLLBAR
========================================================= */
.import-word-page ::-webkit-scrollbar {
  width: 9px;
  height: 9px;
}
.import-word-page ::-webkit-scrollbar-track {
  background: transparent;
}
.import-word-page ::-webkit-scrollbar-thumb {
  background: #c8d1dc;
  border-radius: 999px;
}
.import-word-page.dark ::-webkit-scrollbar-thumb {
  background: #3e4c60;
}
/* =========================================================
   RESPONSIVE — TABLET
========================================================= */
@media (
  max-width: 900px
) {
  .import-word-header {
    grid-template-columns: auto 1fr;
  }
  .import-header-actions {
    grid-column: 1 / -1;
    justify-content: flex-end;
  }
  .import-tabs {
    grid-template-columns: repeat( 2, 1fr );
  }
  .import-settings-page {
    grid-template-columns: 1fr;
  }
  .import-status-bar {
    align-items: flex-start;
    flex-direction: column;
  }
  .import-status-bar
  > div:last-child {
    justify-content: flex-start;
  }
  .import-selected-file {
    grid-template-columns: auto 1fr auto;
  }
  .import-selected-file-result {
    grid-column: 1 / -1;
    flex-direction: row;
    align-items: center;
  }
}
/* =========================================================
   RESPONSIVE — MOBILE
========================================================= */
@media (
  max-width: 640px
) {
  .import-word-page {
    padding-bottom: 40px;
  }
  .import-word-header {
    position: relative;
    padding: 17px 17px;
    gap: 13px;
  }
  .import-back-btn {
    width: 40px;
    height: 40px;
  }
  .import-header-title h1 {
    font-size: 22px;
  }
  .import-header-actions {
    width: 100%;
    display: grid;
    grid-template-columns: repeat( 2, minmax( 0, 1fr ) );
  }
  .import-header-actions
  .import-save-btn:only-child {
    grid-column: 1 / -1;
  }
  .import-previous-btn,
  .import-save-btn {
    width: 100%;
    padding: 0 12px;
  }
  .import-tabs,
  .import-status-bar,
  .import-word-content,
  .import-settings-page {
    width: calc( 100% - 28px );
  }
  .import-tabs {
    margin-top: 14px;
    padding: 6px;
  }
  .import-tab {
    min-height: 52px;
    padding: 0 8px;
    font-size: 13px;
  }
  .import-tab > svg {
    display: none;
  }
  .import-tab-number {
    width: 24px;
    height: 24px;
  }
  .import-word-content,
  .import-settings-page {
    margin-top: 16px;
  }
  .import-word-section {
    padding: 20px;
    border-radius: 20px;
  }
  .import-section-heading {
    gap: 12px;
    margin-bottom: 21px;
  }
  .import-section-icon {
    width: 42px;
    min-width: 42px;
    height: 42px;
    border-radius: 13px;
  }
  .import-section-heading h2 {
    font-size: 20px;
  }
  .import-drop-zone {
    min-height: 290px;
    padding: 32px 17px;
  }
  .import-drop-icon {
    width: 67px;
    height: 67px;
    border-radius: 20px;
    font-size: 32px;
  }
  .import-selected-file {
    grid-template-columns: auto minmax( 0, 1fr ) auto;
    gap: 12px;
  }
  .import-selected-file-icon {
    width: 47px;
    height: 47px;
    border-radius: 14px;
  }
  .import-selected-file-result {
    grid-column: 1 / -1;
  }
  .import-schedule-grid {
    grid-template-columns: 1fr;
  }
  .import-radio-grid {
    grid-template-columns: 1fr;
  }
  .import-setting-option {
    grid-template-columns: auto minmax( 0, 1fr ) auto;
  }
  .import-setting-option
  > input {
    display: none;
  }
  .import-timer-card {
    align-items: flex-start;
    flex-direction: column;
  }
  .import-question-summary {
    padding: 23px 20px;
    align-items: flex-start;
  }
  .import-question-summary h2 {
    font-size: 21px;
  }
  .import-question-total {
    min-width: 81px;
    min-height: 74px;
  }
  .import-question-card {
    padding: 18px;
    border-radius: 19px;
  }
  .import-question-header {
    grid-template-columns: auto minmax( 0, 1fr );
  }
  .import-question-actions {
    grid-column: 1 / -1;
    justify-content: flex-end;
  }
  .import-score-settings {
    grid-template-columns: 1fr;
  }
}
/* =========================================================
   VERY SMALL MOBILE
========================================================= */
@media (
  max-width: 420px
) {
  .import-tabs {
    grid-template-columns: 1fr 1fr;
  }
  .import-tab {
    justify-content: flex-start;
    padding: 0 12px;
  }
  .import-question-summary {
    flex-direction: column;
  }
  .import-question-total {
    width: 100%;
    min-height: 64px;
    flex-direction: row;
    gap: 8px;
  }
  .import-question-total span {
    margin-top: 0;
  }
  .import-option-row {
    grid-template-columns: 30px minmax( 0, 1fr ) 34px;
  }
  .import-option-row > span {
    width: 30px;
    height: 30px;
  }
  .import-option-row button {
    width: 34px;
    height: 34px;
  }
}
`;
// =========================================================
// STORAGE KEYS
// =========================================================
const FORMS_STORAGE_KEY =
  "hidocs_forms";
const NEW_FORM_STORAGE_KEY =
  "hidocs_new_form";
// =========================================================
// FILE CONFIGURATION
// =========================================================
const MAXIMUM_WORD_SIZE =
  10 * 1024 * 1024;
// =========================================================
// IMPORT WORD
// =========================================================
function ImportWord() {
  const navigate =
    useNavigate();
  const {
    darkMode,
  } = useContext(
    ThemeContext
  );
  const fileInputRef =
    useRef(null);
  // =========================================================
  // TAB
  // =========================================================
  const [
    activeTab,
    setActiveTab,
  ] = useState(
    "upload"
  );
  const tabOrder = [
    "upload",
    "info",
    "settings",
    "questions",
  ];
  const activeTabIndex =
    tabOrder.indexOf(
      activeTab
    );
  const isFirstTab =
    activeTab ===
    "upload";
  const isLastTab =
    activeTab ===
    "questions";
  // =========================================================
  // IMPORT STATE
  // =========================================================
  const [
    selectedFile,
    setSelectedFile,
  ] = useState(null);
  const [
    importLoading,
    setImportLoading,
  ] = useState(false);
  const [
    importError,
    setImportError,
  ] = useState("");
  const [
    importSuccess,
    setImportSuccess,
  ] = useState(false);
  const [
    importedText,
    setImportedText,
  ] = useState("");
  // =========================================================
  // FORM DATA
  // =========================================================
  const [
    formData,
    setFormData,
  ] = useState({
    title: "",
    customLink: "",
    openDate: "",
    closeDate: "",
    openTime: "",
    closeTime: "",
    shuffleQuestions: false,
    shuffleAnswers: false,
    oneTimeOnly: true,
    activateImmediately: true,
    timerEnabled: true,
    timerDuration: 20,
    responseDays: 30,
    resultMode: "none",
    accessMode: "public",
  });
  // =========================================================
  // QUESTIONS
  // =========================================================
  const [
    questions,
    setQuestions,
  ] = useState([]);
  // =========================================================
  // LINK GENERATED
  // =========================================================
  const [
    linkGenerated,
    setLinkGenerated,
  ] = useState(false);
  // =========================================================
  // SAFE STORAGE READER
  // =========================================================
  const getStoredForms =
    () => {
      try {
        const storedValue =
          localStorage.getItem(
            FORMS_STORAGE_KEY
          );
        if (!storedValue) {
          return [];
        }
        const parsedValue =
          JSON.parse(
            storedValue
          );
        return Array.isArray(
          parsedValue
        )
          ? parsedValue
          : [];
      } catch (error) {
        console.error(
          "Gagal membaca form:",
          error
        );
        return [];
      }
    };
  // =========================================================
  // FORM CHANGE
  // =========================================================
  const handleChange = (
    event
  ) => {
    const {
      name,
      value,
      type,
      checked,
    } = event.target;
    let updatedValue =
      type ===
      "checkbox"
        ? checked
        : value;
    if (
      name ===
      "customLink"
    ) {
      updatedValue =
        String(
          value
        )
          .toLowerCase()
          .replace(
            /\s+/g,
            "-"
          )
          .replace(
            /[^a-z0-9-_]/g,
            ""
          )
          .replace(
            /-+/g,
            "-"
          )
          .replace(
            /^-/,
            ""
          );
    }
    if (
      name ===
      "timerDuration"
    ) {
      if (
        value ===
        ""
      ) {
        updatedValue =
          "";
      } else {
        const numericValue =
          Number(
            value
          );
        updatedValue =
          Number.isFinite(
            numericValue
          )
            ? Math.min(
                Math.max(
                  Math.floor(
                    numericValue
                  ),
                  1
                ),
                1000
              )
            : 1;
      }
    }
    setFormData(
      (
        previous
      ) => ({
        ...previous,
        [name]:
          updatedValue,
      })
    );
    if (
      name ===
        "title" ||
      name ===
        "customLink"
    ) {
      setLinkGenerated(
        false
      );
    }
  };
  // =========================================================
  // LINK HELPERS
  // =========================================================
  const createLinkSlug = (
    value
  ) => {
    return String(
      value ||
      ""
    )
      .trim()
      .toLowerCase()
      .normalize(
        "NFD"
      )
      .replace(
        /[\u0300-\u036f]/g,
        ""
      )
      .replace(
        /[^a-z0-9\s-]/g,
        ""
      )
      .replace(
        /\s+/g,
        "-"
      )
      .replace(
        /-+/g,
        "-"
      )
      .replace(
        /^-|-$/g,
        ""
      );
  };
  const createRandomCode =
    () => {
      return Math.random()
        .toString(
          36
        )
        .slice(
          2,
          7
        )
        .toLowerCase();
  };
  const isCustomLinkUsed = (
    customLink
  ) => {
    return getStoredForms()
      .some(
        (
          form
        ) => {
          return (
            String(
              form.customLink ||
              ""
            )
              .trim()
              .toLowerCase() ===
            String(
              customLink ||
              ""
            )
              .trim()
              .toLowerCase()
          );
        }
      );
  };
  const generateRandomLink =
    () => {
      const titleSlug =
        createLinkSlug(
          formData.title
        );
      if (!titleSlug) {
        alert(
          "Isi Form Title terlebih dahulu."
        );
        return;
      }
      let generatedLink =
        "";
      let attempt =
        0;
      do {
        generatedLink =
          `${titleSlug}-${createRandomCode()}`;
        attempt +=
          1;
      } while (
        isCustomLinkUsed(
          generatedLink
        ) &&
        attempt <
          20
      );
      if (
        isCustomLinkUsed(
          generatedLink
        )
      ) {
        alert(
          "Gagal membuat link. Silakan coba lagi."
        );
        return;
      }
      setFormData(
        (
          previous
        ) => ({
          ...previous,
          customLink:
            generatedLink,
        })
      );
      setLinkGenerated(
        true
      );
      window.setTimeout(
        () => {
          setLinkGenerated(
            false
          );
        },
        1800
      );
  };
  // =========================================================
  // QUESTION TYPE
  // =========================================================
  const questionTypes = [
    {
      type: "multiple",
      label: "Multiple Choice",
      icon:
        <FaListUl />,
    },
    {
      type: "short",
      label: "Short Text",
      icon:
        <FaFont />,
    },
    {
      type: "long",
      label: "Long Text",
      icon:
        <FaAlignLeft />,
    },
    {
      type: "rating",
      label: "Rating",
      icon:
        <FaStar />,
    },
    {
      type: "yesno",
      label: "Yes / No",
      icon:
        <FaCheck />,
    },
    {
      type: "math",
      label: "Math",
      icon:
        <FaCalculator />,
    },
    {
      type: "code",
      label: "Code",
      icon:
        <FaCode />,
    },
  ];
  // =========================================================
  // CREATE QUESTION OBJECT
  // =========================================================
  const createQuestionObject = (
    type = "short"
  ) => {
    return {
      id:
        Date.now() +
        Math.random(),
      title: "",
      question: "",
      type,
      required: true,
      scoring: false,
      points: 1,
      correctAnswer: "",
      options:
        type ===
        "multiple"
          ? [
              "",
              "",
            ]
          : type ===
            "yesno"
          ? [
              "Yes",
              "No",
            ]
          : [],
      ratingMax:
        type ===
        "rating"
          ? 5
          : null,
      image: "",
      imageName: "",
      imageAnswerType: "",
      imageOptions:
        [],
    };
  };
  // =========================================================
  // WORD PARSER
  //
  // Format yang dikenali:
  //
  // 1. Pertanyaan...
  // A. Pilihan
  // B. Pilihan
  // C. Pilihan
  // Kunci: B
  // Poin: 2
  //
  // [SHORT] Pertanyaan...
  // [LONG] Pertanyaan...
  // [YESNO] Pertanyaan...
  // [RATING] Pertanyaan...
  // [MATH] Pertanyaan...
  // [CODE] Pertanyaan...
  //
  // =========================================================
  const parseWordQuestions = (
    rawText
  ) => {
    const cleanText =
      String(
        rawText ||
        ""
      )
        .replace(
          /\r/g,
          ""
        )
        .replace(
          /\u00a0/g,
          " "
        );
    const lines =
      cleanText
        .split("\n")
        .map(
          (
            line
          ) =>
            line.trim()
        )
        .filter(
          Boolean
        );
    const parsedQuestions =
      [];
    let currentQuestion =
      null;
    const saveCurrentQuestion =
      () => {
        if (!currentQuestion) {
          return;
        }
        if (
          !String(
            currentQuestion.title ||
            ""
          ).trim()
        ) {
          currentQuestion =
            null;
          return;
        }
        if (
          currentQuestion.type ===
            "multiple" &&
          currentQuestion.options.length <
            2
        ) {
          currentQuestion.type =
            "short";
          currentQuestion.options =
            [];
        }
        parsedQuestions.push(
          currentQuestion
        );
        currentQuestion =
          null;
      };
    const detectTypeFromQuestion =
      (
        value
      ) => {
        const text =
          String(
            value
          );
        const upper =
          text.toUpperCase();
        if (
          upper.startsWith(
            "[SHORT]"
          )
        ) {
          return {
            type: "short",
            title:
              text.replace(
                /^\[SHORT\]\s*/i,
                ""
              ),
          };
        }
        if (
          upper.startsWith(
            "[LONG]"
          )
        ) {
          return {
            type: "long",
            title:
              text.replace(
                /^\[LONG\]\s*/i,
                ""
              ),
          };
        }
        if (
          upper.startsWith(
            "[YESNO]"
          )
        ) {
          return {
            type: "yesno",
            title:
              text.replace(
                /^\[YESNO\]\s*/i,
                ""
              ),
          };
        }
        if (
          upper.startsWith(
            "[RATING]"
          )
        ) {
          return {
            type: "rating",
            title:
              text.replace(
                /^\[RATING\]\s*/i,
                ""
              ),
          };
        }
        if (
          upper.startsWith(
            "[MATH]"
          )
        ) {
          return {
            type: "math",
            title:
              text.replace(
                /^\[MATH\]\s*/i,
                ""
              ),
          };
        }
        if (
          upper.startsWith(
            "[CODE]"
          )
        ) {
          return {
            type: "code",
            title:
              text.replace(
                /^\[CODE\]\s*/i,
                ""
              ),
          };
        }
        return {
          type: "short",
          title:
            text,
        };
      };
    lines.forEach(
      (
        line
      ) => {
        // =====================================================
        // SKIP FORM TITLE
        // =====================================================
        if (
          /^judul\s*:/i.test(
            line
          )
        ) {
          return;
        }
        // =====================================================
        // QUESTION NUMBER
        //
        // 1. Pertanyaan
        // 2) Pertanyaan
        // =====================================================
        const numberedQuestionMatch =
          line.match(
            /^(\d+)[.)]\s+(.+)$/
          );
        if (
          numberedQuestionMatch
        ) {
          saveCurrentQuestion();
          const detected =
            detectTypeFromQuestion(
              numberedQuestionMatch[
                2
              ]
            );
          currentQuestion = {
            ...createQuestionObject(
              detected.type
            ),
            title:
              detected.title,
            question:
              detected.title,
          };
          return;
        }
        // =====================================================
        // QUESTION WITH TYPE BUT NO NUMBER
        // =====================================================
        if (
          /^\[(SHORT|LONG|YESNO|RATING|MATH|CODE)\]/i.test(
            line
          )
        ) {
          saveCurrentQuestion();
          const detected =
            detectTypeFromQuestion(
              line
            );
          currentQuestion = {
            ...createQuestionObject(
              detected.type
            ),
            title:
              detected.title,
            question:
              detected.title,
          };
          return;
        }
        // =====================================================
        // MULTIPLE CHOICE OPTION
        //
        // A. Jawaban
        // B) Jawaban
        // =====================================================
        const optionMatch =
          line.match(
            /^([A-Z])[.)]\s+(.+)$/i
          );
        if (
          optionMatch &&
          currentQuestion
        ) {
          if (
            currentQuestion.type ===
            "short"
          ) {
            currentQuestion.type =
              "multiple";
            currentQuestion.options =
              [];
          }
          if (
            currentQuestion.type ===
            "multiple"
          ) {
            currentQuestion.options.push(
              optionMatch[
                2
              ].trim()
            );
          }
          return;
        }
        // =====================================================
        // CORRECT ANSWER
        //
        // Kunci: A
        // Jawaban: B
        // Correct Answer: C
        // =====================================================
        const answerMatch =
          line.match(
            /^(?:kunci(?:\s+jawaban)?|jawaban|correct\s+answer)\s*:\s*(.+)$/i
          );
        if (
          answerMatch &&
          currentQuestion
        ) {
          const rawCorrectAnswer =
            answerMatch[
              1
            ].trim();
          let correctAnswer =
            rawCorrectAnswer;
          if (
            currentQuestion.type ===
              "multiple"
          ) {
            const letterMatch =
              rawCorrectAnswer.match(
                /^([A-Z])(?:[.)])?$/i
              );
            if (
              letterMatch
            ) {
              const optionIndex =
                letterMatch[
                  1
                ]
                  .toUpperCase()
                  .charCodeAt(
                    0
                  ) -
                65;
              if (
                currentQuestion.options[
                  optionIndex
                ] !==
                undefined
              ) {
                correctAnswer =
                  currentQuestion.options[
                    optionIndex
                  ];
              }
            }
          }
          currentQuestion.correctAnswer =
            correctAnswer;
          currentQuestion.scoring =
            true;
          return;
        }
        // =====================================================
        // POINTS
        // =====================================================
        const pointsMatch =
          line.match(
            /^(?:poin|point|points|nilai)\s*:\s*(\d+)$/i
          );
        if (
          pointsMatch &&
          currentQuestion
        ) {
          currentQuestion.points =
            Math.max(
              Number(
                pointsMatch[
                  1
                ]
              ) ||
              1,
              1
            );
          currentQuestion.scoring =
            true;
          return;
        }
        // =====================================================
        // REQUIRED
        // =====================================================
        const requiredMatch =
          line.match(
            /^required\s*:\s*(yes|no|true|false|ya|tidak)$/i
          );
        if (
          requiredMatch &&
          currentQuestion
        ) {
          const value =
            requiredMatch[
              1
            ]
              .toLowerCase();
          currentQuestion.required =
            (
              value ===
                "yes" ||
              value ===
                "true" ||
              value ===
                "ya"
            );
          return;
        }
        // =====================================================
        // EXTRA TEXT
        //
        // Jika belum ada current question,
        // teks dianggap sebagai pertanyaan baru.
        // =====================================================
        if (
          !currentQuestion
        ) {
          const detected =
            detectTypeFromQuestion(
              line
            );
          currentQuestion = {
            ...createQuestionObject(
              detected.type
            ),
            title:
              detected.title,
            question:
              detected.title,
          };
        } else {
          currentQuestion.title =
            `${currentQuestion.title} ${line}`
              .trim();
          currentQuestion.question =
            currentQuestion.title;
        }
      }
    );
    saveCurrentQuestion();
    return parsedQuestions;
  };
  // =========================================================
  // DETECT TITLE FROM WORD
  // =========================================================
  const detectFormTitle = (
    rawText,
    fileName
  ) => {
    const lines =
      String(
        rawText ||
        ""
      )
        .replace(
          /\r/g,
          ""
        )
        .split("\n")
        .map(
          (
            line
          ) =>
            line.trim()
        )
        .filter(
          Boolean
        );
    const explicitTitle =
      lines.find(
        (
          line
        ) =>
          /^judul\s*:/i.test(
            line
          )
      );
    if (
      explicitTitle
    ) {
      return explicitTitle
        .replace(
          /^judul\s*:/i,
          ""
        )
        .trim();
    }
    const firstLine =
      lines[
        0
      ];
    if (
      firstLine &&
      !/^(\d+)[.)]\s+/.test(
        firstLine
      ) &&
      !/^\[(SHORT|LONG|YESNO|RATING|MATH|CODE)\]/i.test(
        firstLine
      )
    ) {
      return firstLine;
    }
    return String(
      fileName ||
      "Imported Word Form"
    )
      .replace(
        /\.docx$/i,
        ""
      )
      .trim();
  };
  // =========================================================
  // REMOVE TITLE FROM IMPORT TEXT
  // =========================================================
  const removeDetectedTitle = (
    rawText,
    title
  ) => {
    const lines =
      String(
        rawText ||
        ""
      )
        .replace(
          /\r/g,
          ""
        )
        .split("\n");
    let titleRemoved =
      false;
    return lines
      .filter(
        (
          line
        ) => {
          const cleanLine =
            line.trim();
          if (
            titleRemoved
          ) {
            return true;
          }
          if (
            /^judul\s*:/i.test(
              cleanLine
            )
          ) {
            titleRemoved =
              true;
            return false;
          }
          if (
            cleanLine ===
            title
          ) {
            titleRemoved =
              true;
            return false;
          }
          return true;
        }
      )
      .join("\n");
  };
  // =========================================================
  // IMPORT WORD
  // =========================================================
  const importWordFile =
  async (
    file
  ) => {
    if (!file) {
      return;
    }
    setImportError("");
    setImportSuccess(false);
    const lowerName =
      String(file.name || "")
        .toLowerCase();
    if (
      !lowerName.endsWith(
        ".docx"
      )
    ) {
      setImportError(
        "File harus berformat .docx."
      );
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
      return;
    }
    if (
      file.size >
      MAXIMUM_WORD_SIZE
    ) {
      setImportError(
        "Ukuran file Word maksimal 10 MB."
      );
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
      return;
    }
    setImportLoading(true);
    try {
      // ============================================
      // BACA FILE WORD
      // ============================================
      const arrayBuffer =
        await file.arrayBuffer();
      if (!arrayBuffer) {
        throw new Error(
          "File Word tidak dapat dibaca."
        );
      }
      // ============================================
      // PASTIKAN MAMMOTH TERSEDIA
      // ============================================
      if (
        typeof mammoth.extractRawText !==
        "function"
      ) {
        throw new Error(
          "Mammoth gagal dimuat."
        );
      }
      // ============================================
      // WORD -> RAW TEXT
      // ============================================
      const result =
        await mammoth.extractRawText({
          arrayBuffer,
        });
      const rawText =
        String(
          result?.value ||
          ""
        )
          .replace(/\r/g, "")
          .replace(/\u00a0/g, " ")
          .trim();
      console.log(
        "WORD RAW TEXT:",
        rawText
      );
      if (!rawText) {
        throw new Error(
          "Dokumen tidak memiliki teks yang dapat dibaca."
        );
      }
      // ============================================
      // DETECT TITLE
      // ============================================
      const detectedTitle =
        detectFormTitle(
          rawText,
          file.name
        );
      const safeTitle =
        String(
          detectedTitle ||
          file.name.replace(
            /\.docx$/i,
            ""
          ) ||
          "Imported Word Form"
        ).trim();
      // ============================================
      // REMOVE TITLE
      // ============================================
      const questionText =
        removeDetectedTitle(
          rawText,
          safeTitle
        );
      // ============================================
      // PARSE QUESTIONS
      // ============================================
      const parsedQuestions =
        parseWordQuestions(
          questionText
        );
      console.log(
        "PARSED QUESTIONS:",
        parsedQuestions
      );
      if (
        !Array.isArray(
          parsedQuestions
        ) ||
        parsedQuestions.length === 0
      ) {
        throw new Error(
          "Tidak ada pertanyaan yang berhasil ditemukan."
        );
      }
      // ============================================
      // NORMALIZE QUESTIONS
      // ============================================
      const safeQuestions =
        parsedQuestions.map(
          (
            question,
            index
          ) => {
            const validTypes = [
              "multiple",
              "short",
              "long",
              "rating",
              "yesno",
              "math",
              "code",
            ];
            let type =
              String(
                question.type ||
                "short"
              ).toLowerCase();
            if (
              !validTypes.includes(
                type
              )
            ) {
              type =
                "short";
            }
            let options =
              Array.isArray(
                question.options
              )
                ? question.options.map(
                    option =>
                      String(
                        option ?? ""
                      ).trim()
                  )
                : [];
            if (
              type ===
              "yesno"
            ) {
              options = [
                "Yes",
                "No",
              ];
            }
            if (
              type ===
                "multiple" &&
              options.length < 2
            ) {
              type =
                "short";
              options = [];
            }
            if (
              ![
                "multiple",
                "yesno",
              ].includes(type)
            ) {
              options = [];
            }
            const title =
              String(
                question.title ||
                question.question ||
                `Question ${index + 1}`
              ).trim();
            return {
              ...question,
              id:
                question.id ||
                Date.now() +
                index +
                Math.random(),
              number:
                index + 1,
              title,
              question:
                title,
              type,
              required:
                question.required !==
                false,
              scoring:
                Boolean(
                  question.scoring
                ),
              points:
                Math.max(
                  Number(
                    question.points
                  ) || 1,
                  1
                ),
              correctAnswer:
                String(
                  question.correctAnswer ||
                  ""
                ).trim(),
              options,
              ratingMax:
                type ===
                "rating"
                  ? 5
                  : null,
              image: "",
              imageName: "",
              imageAnswerType: "",
              imageOptions:
                [],
            };
          }
        );
      // ============================================
      // CREATE CUSTOM LINK
      // ============================================
      const generatedSlug =
        createLinkSlug(
          safeTitle
        ) ||
        "imported-form";
      let generatedLink =
        `${generatedSlug}-${createRandomCode()}`;
      let attempt = 0;
      while (
        isCustomLinkUsed(
          generatedLink
        ) &&
        attempt < 20
      ) {
        generatedLink =
          `${generatedSlug}-${createRandomCode()}`;
        attempt += 1;
      }
      if (
        isCustomLinkUsed(
          generatedLink
        )
      ) {
        generatedLink =
          `${generatedSlug}-${Date.now()}`;
      }
      // ============================================
      // UPDATE FORM
      // ============================================
      setFormData(
        previous => ({
          ...previous,
          title:
            safeTitle,
          customLink:
            generatedLink,
        })
      );
      // ============================================
      // SIMPAN HASIL IMPORT
      // ============================================
      setQuestions(
        safeQuestions
      );
      setImportedText(
        rawText
      );
      setSelectedFile(
        file
      );
      setImportSuccess(
        true
      );
      setImportError("");
    } catch (error) {
      console.error(
        "Import Word gagal:",
        error
      );
      setSelectedFile(null);
      setQuestions([]);
      setImportedText("");
      setImportSuccess(false);
      setImportError(
        error?.message ||
        "File Word gagal dibaca."
      );
      if (
        fileInputRef.current
      ) {
        fileInputRef.current.value =
          "";
      }
    } finally {
      setImportLoading(false);
    }
  };
  // =========================================================
  // FILE CHANGE
  // =========================================================
  const handleFileChange =
    (
      event
    ) => {
      const file =
        event.target.files?.[
          0
        ];
      if (!file) {
        return;
      }
      importWordFile(
        file
      );
  };
  // =========================================================
  // REMOVE FILE
  // =========================================================
  const removeImportedFile =
    () => {
      setSelectedFile(
        null
      );
      setQuestions([]);
      setImportedText(
        ""
      );
      setImportSuccess(
        false
      );
      setImportError(
        ""
      );
      setFormData(
        (
          previous
        ) => ({
          ...previous,
          title: "",
          customLink: "",
        })
      );
      if (
        fileInputRef.current
      ) {
        fileInputRef.current.value =
          "";
      }
  };
  // =========================================================
  // UPDATE QUESTION
  // =========================================================
  const updateQuestion = (
    questionId,
    field,
    value
  ) => {
    setQuestions(
      (
        previous
      ) =>
        previous.map(
          (
            question
          ) =>
            question.id ===
            questionId
              ? {
                  ...question,
                  [field]:
                    value,
                  ...(
                    field ===
                    "title"
                      ? {
                          question:
                            value,
                        }
                      : {}
                  ),
                }
              : question
        )
    );
  };
  // =========================================================
  // UPDATE OPTION
  // =========================================================
  const updateOption = (
    questionId,
    optionIndex,
    value
  ) => {
    setQuestions(
      (
        previous
      ) =>
        previous.map(
          (
            question
          ) => {
            if (
              question.id !==
              questionId
            ) {
              return question;
            }
            const options = [
              ...(
                question.options ||
                []
              ),
            ];
            const previousOption =
              options[
                optionIndex
              ];
            options[
              optionIndex
            ] =
              value;
            return {
              ...question,
              options,
              correctAnswer:
                question.correctAnswer ===
                previousOption
                  ? value
                  : question.correctAnswer,
            };
          }
        )
    );
  };
  // =========================================================
  // ADD OPTION
  // =========================================================
  const addOption = (
    questionId
  ) => {
    setQuestions(
      (
        previous
      ) =>
        previous.map(
          (
            question
          ) =>
            question.id ===
            questionId
              ? {
                  ...question,
                  options: [
                    ...(
                      question.options ||
                      []
                    ),
                    "",
                  ],
                }
              : question
        )
    );
  };
  // =========================================================
  // DELETE OPTION
  // =========================================================
  const deleteOption = (
    questionId,
    optionIndex
  ) => {
    setQuestions(
      (
        previous
      ) =>
        previous.map(
          (
            question
          ) => {
            if (
              question.id !==
              questionId
            ) {
              return question;
            }
            const options = [
              ...(
                question.options ||
                []
              ),
            ];
            if (
              options.length <=
              2
            ) {
              return question;
            }
            const deletedOption =
              options[
                optionIndex
              ];
            options.splice(
              optionIndex,
              1
            );
            return {
              ...question,
              options,
              correctAnswer:
                question.correctAnswer ===
                deletedOption
                  ? ""
                  : question.correctAnswer,
            };
          }
        )
    );
  };
  // =========================================================
  // DUPLICATE QUESTION
  // =========================================================
  const duplicateQuestion = (
    questionId
  ) => {
    setQuestions(
      (
        previous
      ) => {
        const index =
          previous.findIndex(
            (
              question
            ) =>
              question.id ===
              questionId
          );
        if (
          index ===
          -1
        ) {
          return previous;
        }
        const duplicated = {
          ...previous[
            index
          ],
          id:
            Date.now() +
            Math.random(),
          options: [
            ...(
              previous[
                index
              ].options ||
              []
            ),
          ],
        };
        const result = [
          ...previous,
        ];
        result.splice(
          index +
            1,
          0,
          duplicated
        );
        return result;
      }
    );
  };
  // =========================================================
  // DELETE QUESTION
  // =========================================================
  const deleteQuestion = (
    questionId
  ) => {
    const confirmed =
      window.confirm(
        "Hapus pertanyaan ini?"
      );
    if (!confirmed) {
      return;
    }
    setQuestions(
      (
        previous
      ) =>
        previous.filter(
          (
            question
          ) =>
            question.id !==
            questionId
        )
    );
  };
  // =========================================================
  // ADD QUESTION
  // =========================================================
  const addQuestion =
    () => {
      setQuestions(
        (
          previous
        ) => [
          ...previous,
          createQuestionObject(
            "short"
          ),
        ]
      );
  };
  // =========================================================
  // CHANGE QUESTION TYPE
  // =========================================================
  const changeQuestionType = (
    questionId,
    type
  ) => {
    setQuestions(
      (
        previous
      ) =>
        previous.map(
          (
            question
          ) => {
            if (
              question.id !==
              questionId
            ) {
              return question;
            }
            let options =
              question.options ||
              [];
            if (
              type ===
              "multiple" &&
              options.length <
              2
            ) {
              options = [
                "",
                "",
              ];
            }
            if (
              type ===
              "yesno"
            ) {
              options = [
                "Yes",
                "No",
              ];
            }
            if (
              ![
                "multiple",
                "yesno",
              ].includes(
                type
              )
            ) {
              options =
                [];
            }
            return {
              ...question,
              type,
              options,
              ratingMax:
                type ===
                "rating"
                  ? 5
                  : null,
              correctAnswer: "",
            };
          }
        )
    );
  };
  // =========================================================
  // TIMER BLUR
  // =========================================================
  const handleTimerBlur =
    () => {
      const value =
        Number(
          formData.timerDuration
        );
      const normalized =
        Number.isFinite(
          value
        )
          ? Math.min(
              Math.max(
                Math.floor(
                  value
                ),
                1
              ),
              1000
            )
          : 1;
      setFormData(
        (
          previous
        ) => ({
          ...previous,
          timerDuration:
            normalized,
        })
      );
  };
  // =========================================================
  // SCHEDULE HELPERS
  // =========================================================
  const buildScheduleDateTime = (
    dateValue,
    timeValue,
    defaultTime
  ) => {
    if (!dateValue) {
      return "";
    }
    return `${dateValue}T${timeValue || defaultTime}:00`;
  };
  const getScheduleValues =
    () => {
      const openAt =
        buildScheduleDateTime(
          formData.openDate,
          formData.openTime,
          "00:00"
        );
      const closeAt =
        buildScheduleDateTime(
          formData.closeDate,
          formData.closeTime,
          "23:59"
        );
      return {
        enabled:
          Boolean(
            openAt ||
            closeAt
          ),
        openAt,
        closeAt,
      };
  };
  // =========================================================
  // VALIDATE UPLOAD
  // =========================================================
  const validateUpload =
    () => {
      if (!selectedFile) {
        alert(
          "Upload file Word terlebih dahulu."
        );
        setActiveTab(
          "upload"
        );
        return false;
      }
      if (
        questions.length ===
        0
      ) {
        alert(
          "Tidak ada pertanyaan yang berhasil diimport."
        );
        return false;
      }
      return true;
  };
  // =========================================================
  // VALIDATE INFO
  // =========================================================
  const validateInfo =
    () => {
      const title =
        formData.title
          .trim();
      const link =
        formData.customLink
          .trim();
      if (
        title.length <
        3
      ) {
        alert(
          "Form Title minimal 3 karakter."
        );
        setActiveTab(
          "info"
        );
        return false;
      }
      if (!link) {
        alert(
          "Custom Link harus diisi."
        );
        setActiveTab(
          "info"
        );
        return false;
      }
      if (
        isCustomLinkUsed(
          link
        )
      ) {
        alert(
          "Custom Link sudah digunakan."
        );
        setActiveTab(
          "info"
        );
        return false;
      }
      if (
        formData.openDate &&
        formData.closeDate &&
        formData.closeDate <
          formData.openDate
      ) {
        alert(
          "Close Date tidak boleh lebih awal dari Open Date."
        );
        return false;
      }
      if (
        formData.openDate &&
        formData.closeDate &&
        formData.openDate ===
          formData.closeDate &&
        formData.openTime &&
        formData.closeTime &&
        formData.closeTime <=
          formData.openTime
      ) {
        alert(
          "Close Time harus lebih akhir dari Open Time."
        );
        return false;
      }
      return true;
  };
  // =========================================================
  // VALIDATE SETTINGS
  // =========================================================
  const validateSettings =
    () => {
      if (
        !formData.activateImmediately &&
        !formData.openDate
      ) {
        alert(
          "Isi Open Date jika Activate Immediately dimatikan."
        );
        setActiveTab(
          "info"
        );
        return false;
      }
      if (
        formData.timerEnabled
      ) {
        const duration =
          Number(
            formData.timerDuration
          );
        if (
          !Number.isFinite(
            duration
          ) ||
          duration <
            1 ||
          duration >
            1000
        ) {
          alert(
            "Durasi timer harus 1–1000 menit."
          );
          return false;
        }
      }
      return true;
  };
  // =========================================================
  // VALIDATE QUESTIONS
  // =========================================================
  const validateQuestions =
    () => {
      if (
        questions.length ===
        0
      ) {
        alert(
          "Minimal terdapat satu pertanyaan."
        );
        return false;
      }
      const emptyQuestion =
        questions.findIndex(
          (
            question
          ) =>
            !String(
              question.title ||
              ""
            ).trim()
        );
      if (
        emptyQuestion !==
        -1
      ) {
        alert(
          `Pertanyaan nomor ${emptyQuestion + 1} masih kosong.`
        );
        return false;
      }
      const invalidMultiple =
        questions.findIndex(
          (
            question
          ) => {
            if (
              question.type !==
              "multiple"
            ) {
              return false;
            }
            return (
              !Array.isArray(
                question.options
              ) ||
              question.options.length <
                2 ||
              question.options.some(
                (
                  option
                ) =>
                  !String(
                    option ||
                    ""
                  ).trim()
              )
            );
          }
        );
      if (
        invalidMultiple !==
        -1
      ) {
        alert(
          `Pilihan jawaban pertanyaan nomor ${invalidMultiple + 1} belum lengkap.`
        );
        return false;
      }
      const invalidScore =
        questions.findIndex(
          (
            question
          ) => {
            if (
              !question.scoring
            ) {
              return false;
            }
            return (
              Number(
                question.points
              ) <=
                0 ||
              !String(
                question.correctAnswer ||
                ""
              ).trim()
            );
          }
        );
      if (
        invalidScore !==
        -1
      ) {
        alert(
          `Scoring pertanyaan nomor ${invalidScore + 1} belum lengkap.`
        );
        return false;
      }
      /*
        PENTING:
        resultMode hanya mengatur apa yang boleh dilihat user
        setelah submit. Penilaian internal admin tetap dapat
        digunakan selama Question Scoring aktif.
        none   = user tidak melihat hasil/nilai
        result = user hanya melihat hasil jawaban
        score  = user melihat hasil + nilai
        Admin tetap dapat melihat benar/salah, kunci jawaban,
        poin, dan nilai dari pertanyaan yang memakai scoring.
      */
      return true;
  };
  // =========================================================
  // CHANGE TAB
  // =========================================================
  const changeTab = (
    tab
  ) => {
    const targetIndex =
      tabOrder.indexOf(
        tab
      );
    if (
      targetIndex >=
        1 &&
      !validateUpload()
    ) {
      return;
    }
    if (
      targetIndex >=
        2 &&
      !validateInfo()
    ) {
      return;
    }
    if (
      targetIndex >=
        3 &&
      !validateSettings()
    ) {
      return;
    }
    setActiveTab(
      tab
    );
    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  };
  // =========================================================
  // NEXT
  // =========================================================
  const handleNextStep =
    () => {
      if (
        activeTab ===
          "upload" &&
        !validateUpload()
      ) {
        return;
      }
      if (
        activeTab ===
          "info" &&
        !validateInfo()
      ) {
        return;
      }
      if (
        activeTab ===
          "settings" &&
        !validateSettings()
      ) {
        return;
      }
      if (
        activeTabIndex <
        tabOrder.length -
          1
      ) {
        setActiveTab(
          tabOrder[
            activeTabIndex +
            1
          ]
        );
        window.scrollTo({
          top: 0,
          behavior: "smooth",
        });
      }
  };
  // =========================================================
  // PREVIOUS
  // =========================================================
  const handlePreviousStep =
    () => {
      if (
        activeTabIndex <=
        0
      ) {
        return;
      }
      setActiveTab(
        tabOrder[
          activeTabIndex -
          1
        ]
      );
      window.scrollTo({
        top: 0,
        behavior: "smooth",
      });
  };
  // =========================================================
  // SAVE FORM
  // =========================================================
  const handleSave =
    () => {
      if (
        !validateUpload() ||
        !validateInfo() ||
        !validateSettings() ||
        !validateQuestions()
      ) {
        return;
      }
      const normalizedLink =
        formData.customLink
          .trim()
          .toLowerCase()
          .replace(
            /\s+/g,
            "-"
          );
      const isPublicForm =
        formData.accessMode ===
        "public";
      const timerDuration =
        formData.timerEnabled
          ? Math.min(
              Math.max(
                Math.floor(
                  Number(
                    formData.timerDuration
                  ) ||
                  1
                ),
                1
              ),
              1000
            )
          : null;
      const schedule =
        getScheduleValues();
      const responseDays =
        Number(
          formData.responseDays
        ) ||
        30;
      const savedForm = {
        id:
          Date.now(),
        title:
          formData.title
            .trim(),
        description: `Imported from Microsoft Word (${selectedFile?.name || "document.docx"}).`,
        type: "Form",
        category: "Form",
        source: "word-import",
        importedFileName:
          selectedFile?.name ||
          "",
        customLink:
          normalizedLink,
        link: `hidocs.app/r/${normalizedLink}`,
        openDate:
          formData.openDate,
        closeDate:
          formData.closeDate,
        openTime:
          formData.openTime,
        closeTime:
          formData.closeTime,
        active: true,
        activationMode:
          formData.activateImmediately
            ? "immediate"
            : "scheduled",
        openAt:
          schedule.openAt,
        closeAt:
          schedule.closeAt,
        schedule: {
          enabled:
            schedule.enabled,
          openAt:
            schedule.openAt,
          closeAt:
            schedule.closeAt,
        },
        responseDays,
        accessMode:
          formData.accessMode,
        showInUserList:
          isPublicForm,
        qrOnly:
          !isPublicForm,
        responses: 0,
        // =====================================================
        // INTERNAL ADMIN GRADING
        // Tidak bergantung pada resultMode user.
        // =====================================================
        grading: {
          enabled:
            questions.some(
              (question) =>
                Boolean(
                  question.scoring
                )
            ),
          totalPoints:
            questions.reduce(
              (
                total,
                question
              ) => {
                if (
                  !question.scoring
                ) {
                  return total;
                }
                return (
                  total +
                  Math.max(
                    Number(
                      question.points
                    ) ||
                    1,
                    1
                  )
                );
              },
              0
            ),
          scoredQuestions:
            questions.filter(
              (question) =>
                Boolean(
                  question.scoring
                )
            ).length,
          calculateForAdmin: true,
          userResultMode:
            formData.resultMode,
        },
        timerEnabled:
          Boolean(
            formData.timerEnabled
          ),
        timerDuration,
        duration:
          timerDuration,
        timer: {
          enabled:
            Boolean(
              formData.timerEnabled
            ),
          mode: "custom",
          duration:
            timerDuration,
        },
        settings: {
          shuffleQuestions:
            Boolean(
              formData.shuffleQuestions
            ),
          shuffleAnswers:
            Boolean(
              formData.shuffleAnswers
            ),
          oneTimeOnly:
            Boolean(
              formData.oneTimeOnly
            ),
          activateImmediately:
            Boolean(
              formData.activateImmediately
            ),
          activationMode:
            formData.activateImmediately
              ? "immediate"
              : "scheduled",
          scheduleEnabled:
            schedule.enabled,
          openAt:
            schedule.openAt,
          closeAt:
            schedule.closeAt,
          schedule: {
            enabled:
              schedule.enabled,
            openAt:
              schedule.openAt,
            closeAt:
              schedule.closeAt,
          },
          timerEnabled:
            Boolean(
              formData.timerEnabled
            ),
          timerDuration,
          timer: {
            enabled:
              Boolean(
                formData.timerEnabled
              ),
            mode: "custom",
            duration:
              timerDuration,
          },
          responseDays,
          resultMode:
            formData.resultMode,
          accessMode:
            formData.accessMode,
          showInUserList:
            isPublicForm,
          qrOnly:
            !isPublicForm,
        },
        questions:
          questions.map(
            (
              question,
              index
            ) => {
              const scoringEnabled =
                Boolean(
                  question.scoring
                );
              const normalizedPoints =
                scoringEnabled
                  ? Math.max(
                      Number(
                        question.points
                      ) ||
                      1,
                      1
                    )
                  : 0;
              const normalizedCorrectAnswer =
                scoringEnabled
                  ? String(
                      question.correctAnswer ||
                      ""
                    ).trim()
                  : "";
              const normalizedOptions =
                (
                  question.options ||
                  []
                ).map(
                  (option) =>
                    String(
                      option ||
                      ""
                    ).trim()
                );
              return {
                ...question,
                number:
                  index +
                  1,
                title:
                  String(
                    question.title ||
                    ""
                  ).trim(),
                question:
                  String(
                    question.title ||
                    ""
                  ).trim(),
                required:
                  question.required !==
                  false,
                // ===============================================
                // INTERNAL ADMIN SCORING
                // ===============================================
                scoring:
                  scoringEnabled,
                points:
                  normalizedPoints,
                correctAnswer:
                  normalizedCorrectAnswer,
                grading: {
                  enabled:
                    scoringEnabled,
                  points:
                    normalizedPoints,
                  correctAnswer:
                    normalizedCorrectAnswer,
                },
                options:
                  normalizedOptions,
                image: "",
                imageName: "",
                imageAnswerType: "",
                imageOptions:
                  [],
              };
            }
          ),
        createdAt:
          new Date()
            .toISOString(),
      };
      try {
        const existingForms =
          getStoredForms();
        if (
          existingForms.some(
            (
              form
            ) =>
              String(
                form.customLink ||
                ""
              )
                .trim()
                .toLowerCase() ===
              normalizedLink
                .toLowerCase()
          )
        ) {
          alert(
            "Custom Link sudah digunakan."
          );
          setActiveTab(
            "info"
          );
          return;
        }
        const updatedForms = [
          ...existingForms,
          savedForm,
        ];
        localStorage.setItem(
          FORMS_STORAGE_KEY,
          JSON.stringify(
            updatedForms
          )
        );
        localStorage.setItem(
          NEW_FORM_STORAGE_KEY,
          JSON.stringify(
            savedForm
          )
        );
        window.dispatchEvent(
          new CustomEvent(
            "hidocs-forms-updated",
            {
              detail: {
                formId:
                  savedForm.id,
              },
            }
          )
        );
        alert(
          isPublicForm
            ? "Form Word berhasil diimport dan dipublikasikan."
            : "Form Word berhasil diimport sebagai QR Code Only."
        );
        navigate(
          "/admin/forms",
          {
            replace: true,
          }
        );
      } catch (error) {
        console.error(
          "Gagal menyimpan form:",
          error
        );
        alert(
          "Form gagal disimpan."
        );
      }
  };
  // =========================================================
  // RENDER TOGGLE
  // =========================================================
  const renderToggle = (
    name,
    icon,
    title,
    description
  ) => (
    <label className="import-setting-option">
      <div className="import-setting-icon">
        {icon}
      </div>
      <div className="import-setting-content">
        <strong>
          {title}
        </strong>
        <span>
          {description}
        </span>
      </div>
      <input
        type="checkbox"
        name={name}
        checked={
          Boolean(
            formData[
              name
            ]
          )
        }
        onChange={
          handleChange
        }
      />
      <span className="import-toggle">
        <span></span>
      </span>
    </label>
  );
  // =========================================================
  // UPLOAD TAB
  // =========================================================
  const renderUploadTab =
    () => (
      <div className="import-word-content">
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaFileWord />
            </div>
            <div>
              <span>
                Step 1
              </span>
              <h2>
                Import Microsoft Word
              </h2>
              <p>
                Upload a .docx document and HiDocs will convert it into form questions.
              </p>
            </div>
          </div>
          {!selectedFile ? (
            <div
              className="import-drop-zone"
              onClick={() =>
                fileInputRef.current
                  ?.click()
              }
            >
              <input
                ref={
                  fileInputRef
                }
                type="file"
                accept=".docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                onChange={
                  handleFileChange
                }
                hidden
              />
              <div className="import-drop-icon">
                <FaFileWord />
              </div>
              <h3>
                Upload Word Document
              </h3>
              <p>
                Select a Microsoft Word .docx file containing your questions.
              </p>
              <button
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  fileInputRef.current
                    ?.click();
                }}
              >
                <FaUpload />
                Choose Word File
              </button>
              <small>
                DOCX • Maximum 10 MB
              </small>
            </div>
          ) : (
            <div className="import-selected-file">
              <div className="import-selected-file-icon">
                <FaFileWord />
              </div>
              <div className="import-selected-file-info">
                <span>
                  Imported Document
                </span>
                <strong>
                  {selectedFile.name}
                </strong>
                <small>
                  {(
                    selectedFile.size /
                    1024
                  ).toFixed(
                    1
                  )}
                  {" "}
                  KB
                </small>
              </div>
              <div className="import-selected-file-result">
                <FaCheckCircle />
                <strong>
                  {questions.length} Questions
                </strong>
                <span>
                  successfully detected
                </span>
              </div>
              <button
                type="button"
                className="import-remove-file"
                onClick={
                  removeImportedFile
                }
              >
                <FaTrash />
              </button>
            </div>
          )}
          {importLoading && (
            <div className="import-processing">
              <span className="import-spinner"></span>
              <div>
                <strong>
                  Reading Word document...
                </strong>
                <p>
                  HiDocs is detecting questions and answers.
                </p>
              </div>
            </div>
          )}
          {importError && (
            <div className="import-message error">
              <FaTimes />
              <span>
                {importError}
              </span>
            </div>
          )}
          {importSuccess && (
            <div className="import-message success">
              <FaCheckCircle />
              <span>
                Word successfully imported. You can continue and review all questions before saving.
              </span>
            </div>
          )}
        </section>
        <section className="import-word-section template-guide">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaInfoCircle />
            </div>
            <div>
              <span>
                Recommended Format
              </span>
              <h2>
                Word Question Format
              </h2>
            </div>
          </div>
          <div className="import-template-example">
            <pre>
{`1. Apa ibu kota negara Indonesia?
A. Surabaya
*B. Nusantara
C. Bandung
D. Medan

2. Pilih hewan mamalia berikut! (boleh lebih dari satu jawaban)
[Checkbox]
*A. Paus
B. Hiu
*C. Kelelawar
D. Buaya

3. Jelaskan pengertian dari fotosintesis!
[Essay]

4. Air mendidih pada suhu .... derajat Celsius.
[Isian]

5. Apakah air mendidih pada suhu 100 derajat Celsius?
*A. Ya
B. Tidak

6. Seberapa puas Anda dengan materi ujian ini?
[Rating 5]

7. Tuliskan rumus luas lingkaran!
[Math]

8. Tuliskan fungsi untuk menjumlahkan dua bilangan!
[Code]

9. Jelaskan isi gambar berikut! (soal dengan gambar)
[Image]

10. Jodohkan negara dengan ibu kotanya!
[Matching]
Indonesia | Jakarta
Jepang | Tokyo
Prancis | Paris
Jerman | Berlin`}
            </pre>
          </div>
          <div style={{ marginTop: '16px', display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
            <a
              href="/templates/template_import.docx"
              download="template-import-hidocs.docx"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 16px',
                backgroundColor: '#2563eb',
                color: '#ffffff',
                borderRadius: '10px',
                fontWeight: '600',
                fontSize: '13px',
                textDecoration: 'none',
              }}
            >
              <FaFileWord /> Unduh Template Resmi (.docx)
            </a>
            <span style={{ fontSize: '13px', color: '#64748b' }}>
              Tanda * di depan opsi (contoh: *B.) menandakan kunci jawaban otomatis.
            </span>
          </div>
        </section>
      </div>
  );
  // =========================================================
  // INFO TAB
  // =========================================================
  const renderInfoTab =
    () => (
      <div className="import-word-content">
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaInfoCircle />
            </div>
            <div>
              <span>
                Step 2
              </span>
              <h2>
                Basic Information
              </h2>
            </div>
          </div>
          <div className="import-field">
            <label>
              Form Title *
            </label>
            <div className="import-input-wrapper">
              <FaFileAlt />
              <input
                type="text"
                name="title"
                value={
                  formData.title
                }
                onChange={
                  handleChange
                }
                placeholder="Form title"
              />
            </div>
          </div>
          <div className="import-field">
            <label>
              Custom Link *
            </label>
            <div className="import-input-wrapper">
              <FaLink />
              <input
                type="text"
                name="customLink"
                value={
                  formData.customLink
                }
                onChange={
                  handleChange
                }
              />
              <button
                type="button"
                className="import-random-link-btn"
                onClick={
                  generateRandomLink
                }
              >
                {linkGenerated
                  ? <FaCheck />
                  : <FaRandom />
                }
              </button>
            </div>
            <small>
              hidocs.app/r/{formData.customLink || "custom-link"}
            </small>
          </div>
        </section>
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaCalendarAlt />
            </div>
            <div>
              <span>
                Availability
              </span>
              <h2>
                Schedule
              </h2>
            </div>
          </div>
          <div className="import-schedule-grid">
            <div className="import-field">
              <label>
                Open Date
              </label>
              <div className="import-input-wrapper">
                <FaCalendarAlt />
                <input
                  type="date"
                  name="openDate"
                  value={
                    formData.openDate
                  }
                  onChange={
                    handleChange
                  }
                />
              </div>
            </div>
            <div className="import-field">
              <label>
                Close Date
              </label>
              <div className="import-input-wrapper">
                <FaCalendarAlt />
                <input
                  type="date"
                  name="closeDate"
                  value={
                    formData.closeDate
                  }
                  onChange={
                    handleChange
                  }
                />
              </div>
            </div>
            <div className="import-field">
              <label>
                Open Time
              </label>
              <div className="import-input-wrapper">
                <FaClock />
                <input
                  type="time"
                  name="openTime"
                  value={
                    formData.openTime
                  }
                  onChange={
                    handleChange
                  }
                />
              </div>
            </div>
            <div className="import-field">
              <label>
                Close Time
              </label>
              <div className="import-input-wrapper">
                <FaClock />
                <input
                  type="time"
                  name="closeTime"
                  value={
                    formData.closeTime
                  }
                  onChange={
                    handleChange
                  }
                />
              </div>
            </div>
          </div>
        </section>
      </div>
  );
  // =========================================================
  // SETTINGS TAB
  // =========================================================
  const renderSettingsTab =
    () => (
      <div className="import-settings-page">
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaCog />
            </div>
            <div>
              <span>
                Step 3
              </span>
              <h2>
                Form Options
              </h2>
            </div>
          </div>
          {renderToggle(
            "shuffleQuestions",
            <FaRandom />,
            "Shuffle question order",
            "Randomize the question order for every respondent."
          )}
          {renderToggle(
            "shuffleAnswers",
            <FaRandom />,
            "Shuffle answer options",
            "Randomize multiple choice answer options."
          )}
          {renderToggle(
            "oneTimeOnly",
            <FaLock />,
            "One-time submission only",
            "Each account can only submit this form once."
          )}
          {renderToggle(
            "activateImmediately",
            <FaPowerOff />,
            "Activate immediately",
            "Make the form available immediately or according to schedule."
          )}
        </section>
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaHourglassHalf />
            </div>
            <div>
              <span>
                Time Limit
              </span>
              <h2>
                Response Timer
              </h2>
            </div>
          </div>
          {renderToggle(
            "timerEnabled",
            <FaClock />,
            "Enable response timer",
            "Automatically end the attempt when the timer reaches zero."
          )}
          <div className="import-timer-card">
            <div>
              <strong>
                Time Limit
              </strong>
              <span>
                Duration for each respondent.
              </span>
            </div>
            <div className="import-timer-input">
              <input
                type="number"
                name="timerDuration"
                min="1"
                max="1000"
                value={
                  formData.timerDuration
                }
                onChange={
                  handleChange
                }
                onBlur={
                  handleTimerBlur
                }
                disabled={
                  !formData.timerEnabled
                }
              />
              <span>
                minutes
              </span>
            </div>
          </div>
          <div className="import-timer-card">
            <div>
              <strong>
                Response Availability
              </strong>
              <span>
                Default response availability.
              </span>
            </div>
            <select
              name="responseDays"
              value={
                formData.responseDays
              }
              onChange={
                handleChange
              }
            >
              <option value="7">
                7 days
              </option>
              <option value="14">
                14 days
              </option>
              <option value="30">
                30 days
              </option>
              <option value="60">
                60 days
              </option>
              <option value="90">
                90 days
              </option>
            </select>
          </div>
        </section>
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaGlobe />
            </div>
            <div>
              <span>
                Distribution
              </span>
              <h2>
                Form Visibility
              </h2>
            </div>
          </div>
          <div className="import-radio-grid">
            <label
              className={
                formData.accessMode ===
                "public"
                  ? "import-choice-card selected"
                  : "import-choice-card"
              }
            >
              <FaGlobe />
              <div>
                <strong>
                  Public Form
                </strong>
                <span>
                  Form appears automatically on the user dashboard.
                </span>
              </div>
              <input
                type="radio"
                name="accessMode"
                value="public"
                checked={
                  formData.accessMode ===
                  "public"
                }
                onChange={
                  handleChange
                }
              />
            </label>
            <label
              className={
                formData.accessMode ===
                "qr-only"
                  ? "import-choice-card selected"
                  : "import-choice-card"
              }
            >
              <FaQrcode />
              <div>
                <strong>
                  QR Code Only
                </strong>
                <span>
                  Hidden from user lists and accessible through QR/direct link.
                </span>
              </div>
              <input
                type="radio"
                name="accessMode"
                value="qr-only"
                checked={
                  formData.accessMode ===
                  "qr-only"
                }
                onChange={
                  handleChange
                }
              />
            </label>
          </div>
        </section>
        <section className="import-word-section">
          <div className="import-section-heading">
            <div className="import-section-icon">
              <FaTrophy />
            </div>
            <div>
              <span>
                Submission
              </span>
              <h2>
                Result & Score
              </h2>
            </div>
          </div>
          <div className="import-result-options">
            {[
              {
                value: "none",
                icon:
                  <FaEyeSlash />,
                title: "Do not show results",
                description: "Users cannot review results after submitting.",
              },
              {
                value: "result",
                icon:
                  <FaEye />,
                title: "Show result only",
                description: "Users can review their submitted questions and answers.",
              },
              {
                value: "score",
                icon:
                  <FaTrophy />,
                title: "Show result and score",
                description: "Users can see correct answers and their score.",
              },
            ].map(
              (
                item
              ) => (
                <label
                  key={
                    item.value
                  }
                  className={
                    formData.resultMode ===
                    item.value
                      ? "import-result-option selected"
                      : "import-result-option"
                  }
                >
                  <div className="import-result-icon">
                    {item.icon}
                  </div>
                  <div>
                    <strong>
                      {item.title}
                    </strong>
                    <span>
                      {item.description}
                    </span>
                  </div>
                  <input
                    type="radio"
                    name="resultMode"
                    value={
                      item.value
                    }
                    checked={
                      formData.resultMode ===
                      item.value
                    }
                    onChange={
                      handleChange
                    }
                  />
                </label>
              )
            )}
          </div>
        </section>
      </div>
  );
  // =========================================================
  // QUESTIONS TAB
  // =========================================================
  const renderQuestionsTab =
    () => (
      <div className="import-word-content">
        <section className="import-question-summary">
          <div>
            <span>
              Step 4
            </span>
            <h2>
              Review Imported Questions
            </h2>
            <p>
              Check the questions detected from Word before saving your form.
            </p>
          </div>
          <div className="import-question-total">
            <strong>
              {questions.length}
            </strong>
            <span>
              Questions
            </span>
          </div>
        </section>
        <div className="import-question-list">
          {questions.map(
            (
              question,
              index
            ) => (
              <article
                key={
                  question.id
                }
                className="import-question-card"
              >
                <div className="import-question-header">
                  <div className="import-question-number">
                    {index + 1}
                  </div>
                  <div className="import-question-type">
                    {
                      questionTypes.find(
                        (
                          item
                        ) =>
                          item.type ===
                          question.type
                      )?.icon ||
                      <FaQuestionCircle />
                    }
                    <span>
                      {
                        questionTypes.find(
                          (
                            item
                          ) =>
                            item.type ===
                            question.type
                        )?.label ||
                        "Question"
                      }
                    </span>
                  </div>
                  <div className="import-question-actions">
                    <button
                      type="button"
                      onClick={() =>
                        duplicateQuestion(
                          question.id
                        )
                      }
                    >
                      <FaCopy />
                    </button>
                    <button
                      type="button"
                      className="danger"
                      onClick={() =>
                        deleteQuestion(
                          question.id
                        )
                      }
                    >
                      <FaTrash />
                    </button>
                  </div>
                </div>
                <div className="import-field">
                  <label>
                    Question Type
                  </label>
                  <select
                    value={
                      question.type
                    }
                    onChange={(event) =>
                      changeQuestionType(
                        question.id,
                        event.target.value
                      )
                    }
                  >
                    {questionTypes.map(
                      (
                        type
                      ) => (
                        <option
                          key={
                            type.type
                          }
                          value={
                            type.type
                          }
                        >
                          {type.label}
                        </option>
                      )
                    )}
                  </select>
                </div>
                <div className="import-field">
                  <label>
                    Question
                  </label>
                  <textarea
                    rows="3"
                    value={
                      question.title
                    }
                    onChange={(event) =>
                      updateQuestion(
                        question.id,
                        "title",
                        event.target.value
                      )
                    }
                  />
                </div>
                {question.type ===
                  "multiple" && (
                  <div className="import-options-section">
                    <label>
                      Answer Options
                    </label>
                    {(
                      question.options ||
                      []
                    ).map(
                      (
                        option,
                        optionIndex
                      ) => (
                        <div
                          key={
                            `${question.id}-${optionIndex}`
                          }
                          className="import-option-row"
                        >
                          <span>
                            {String.fromCharCode(
                              65 +
                              optionIndex
                            )}
                          </span>
                          <input
                            type="text"
                            value={
                              option
                            }
                            onChange={(event) =>
                              updateOption(
                                question.id,
                                optionIndex,
                                event.target.value
                              )
                            }
                          />
                          {question.options.length >
                            2 && (
                            <button
                              type="button"
                              onClick={() =>
                                deleteOption(
                                  question.id,
                                  optionIndex
                                )
                              }
                            >
                              <FaMinus />
                            </button>
                          )}
                        </div>
                      )
                    )}
                    <button
                      type="button"
                      className="import-add-option"
                      onClick={() =>
                        addOption(
                          question.id
                        )
                      }
                    >
                      <FaPlus />
                      Add Option
                    </button>
                  </div>
                )}
                {question.type ===
                  "yesno" && (
                  <div className="import-yesno-preview">
                    <span>
                      <FaCircle />
                      Yes
                    </span>
                    <span>
                      <FaCircle />
                      No
                    </span>
                  </div>
                )}
                {question.type ===
                  "rating" && (
                  <div className="import-rating-preview">
                    {[1, 2, 3, 4, 5].map(
                      (
                        value
                      ) => (
                        <span
                          key={
                            value
                          }
                        >
                          <FaStar />
                          {value}
                        </span>
                      )
                    )}
                  </div>
                )}
                <div className="import-question-settings">
                  <label className="import-inline-toggle">
                    <input
                      type="checkbox"
                      checked={
                        question.required
                      }
                      onChange={(event) =>
                        updateQuestion(
                          question.id,
                          "required",
                          event.target.checked
                        )
                      }
                    />
                    <span>
                      Required Question
                    </span>
                  </label>
                  <label className="import-inline-toggle">
                    <input
                      type="checkbox"
                      checked={
                        question.scoring
                      }
                      onChange={(event) =>
                        updateQuestion(
                          question.id,
                          "scoring",
                          event.target.checked
                        )
                      }
                    />
                    <span>
                      Question Scoring
                    </span>
                  </label>
                </div>
                {question.scoring && (
                  <div className="import-score-settings">
                    <div className="import-field">
                      <label>
                        Points
                      </label>
                      <input
                        type="number"
                        min="1"
                        value={
                          question.points
                        }
                        onChange={(event) =>
                          updateQuestion(
                            question.id,
                            "points",
                            Number(
                              event.target.value
                            )
                          )
                        }
                      />
                    </div>
                    <div className="import-field">
                      <label>
                        Correct Answer
                      </label>
                      {question.type ===
                        "multiple" ||
                      question.type ===
                        "yesno" ? (
                        <select
                          value={
                            question.correctAnswer ||
                            ""
                          }
                          onChange={(event) =>
                            updateQuestion(
                              question.id,
                              "correctAnswer",
                              event.target.value
                            )
                          }
                        >
                          <option value="">
                            Select correct answer
                          </option>
                          {(
                            question.type ===
                            "yesno"
                              ? [
                                  "Yes",
                                  "No",
                                ]
                              : question.options ||
                                []
                          ).map(
                            (
                              option,
                              optionIndex
                            ) => (
                              <option
                                key={
                                  `${question.id}-correct-${optionIndex}`
                                }
                                value={
                                  option
                                }
                              >
                                {option}
                              </option>
                            )
                          )}
                        </select>
                      ) : question.type ===
                        "rating" ? (
                        <select
                          value={
                            question.correctAnswer ||
                            ""
                          }
                          onChange={(event) =>
                            updateQuestion(
                              question.id,
                              "correctAnswer",
                              event.target.value
                            )
                          }
                        >
                          <option value="">
                            Select rating
                          </option>
                          {[1, 2, 3, 4, 5].map(
                            (
                              value
                            ) => (
                              <option
                                key={
                                  value
                                }
                                value={
                                  String(
                                    value
                                  )
                                }
                              >
                                {value}
                              </option>
                            )
                          )}
                        </select>
                      ) : (
                        <input
                          type="text"
                          value={
                            question.correctAnswer ||
                            ""
                          }
                          onChange={(event) =>
                            updateQuestion(
                              question.id,
                              "correctAnswer",
                              event.target.value
                            )
                          }
                          placeholder="Enter correct answer"
                        />
                      )}
                    </div>
                    <small className="import-score-help">
                      Correct answer and points are used for automatic grading and admin result analysis, even when user score visibility is disabled.
                    </small>
                  </div>
                )}
              </article>
            )
          )}
        </div>
        <button
          type="button"
          className="import-add-question-btn"
          onClick={
            addQuestion
          }
        >
          <FaPlus />
          Add Question Manually
        </button>
      </div>
  );
  // =========================================================
  // IMPORT SUMMARY
  // =========================================================
  const importedSummary =
    useMemo(
      () => {
        const multiple =
          questions.filter(
            (
              question
            ) =>
              question.type ===
              "multiple"
          ).length;
        const scoring =
          questions.filter(
            (
              question
            ) =>
              question.scoring
          ).length;
        return {
          multiple,
          scoring,
        };
      },
      [
        questions,
      ]
    );
  // =========================================================
  // RETURN
  // =========================================================
  return (
    <div
      className={
        darkMode
          ? "import-word-page dark"
          : "import-word-page"
      }
    >
      <style>{importWordStyles}</style>
      {/* =====================================================
          HEADER
      ===================================================== */}
      <header className="import-word-header">
        <button
          type="button"
          className="import-back-btn"
          onClick={() =>
            navigate(
              "/admin"
            )
          }
        >
          <FaArrowLeft />
        </button>
        <div className="import-header-title">
          <span>
            Form Builder
          </span>
          <h1>
            Import Word
          </h1>
        </div>
        <div className="import-header-actions">
          {!isFirstTab && (
            <button
              type="button"
              className="import-previous-btn"
              onClick={
                handlePreviousStep
              }
            >
              Previous
            </button>
          )}
          {isLastTab ? (
            <button
              type="button"
              className="import-save-btn"
              onClick={
                handleSave
              }
            >
              <FaCheck />
              Save Form
            </button>
          ) : (
            <button
              type="button"
              className="import-save-btn"
              onClick={
                handleNextStep
              }
              disabled={
                activeTab ===
                  "upload" &&
                (
                  importLoading ||
                  !importSuccess
                )
              }
            >
              Next
              <FaArrowRight />
            </button>
          )}
        </div>
      </header>
      {/* =====================================================
          STEP NAVIGATION
      ===================================================== */}
      <nav className="import-tabs">
        {[
          {
            key: "upload",
            number: 1,
            icon:
              <FaFileWord />,
            label: "Import Word",
          },
          {
            key: "info",
            number: 2,
            icon:
              <FaInfoCircle />,
            label: "Info",
          },
          {
            key: "settings",
            number: 3,
            icon:
              <FaCog />,
            label: "Settings",
          },
          {
            key: "questions",
            number: 4,
            icon:
              <FaQuestionCircle />,
            label: "Review",
          },
        ].map(
          (
            tab
          ) => (
            <button
              type="button"
              key={
                tab.key
              }
              className={
                activeTab ===
                tab.key
                  ? "import-tab active"
                  : "import-tab"
              }
              onClick={() =>
                changeTab(
                  tab.key
                )
              }
            >
              <span className="import-tab-number">
                {tab.number}
              </span>
              {tab.icon}
              <span>
                {tab.label}
              </span>
            </button>
          )
        )}
      </nav>
      {/* =====================================================
          IMPORT STATUS BAR
      ===================================================== */}
      {selectedFile &&
      activeTab !==
        "upload" && (
        <div className="import-status-bar">
          <div>
            <FaFileWord />
            <span>
              {selectedFile.name}
            </span>
          </div>
          <div>
            <strong>
              {questions.length}
            </strong>
            questions
            <strong>
              {importedSummary.multiple}
            </strong>
            multiple choice
            <strong>
              {importedSummary.scoring}
            </strong>
            scored
          </div>
        </div>
      )}
      {/* =====================================================
          PAGE CONTENT
      ===================================================== */}
      {activeTab ===
        "upload" &&
        renderUploadTab()}
      {activeTab ===
        "info" &&
        renderInfoTab()}
      {activeTab ===
        "settings" &&
        renderSettingsTab()}
      {activeTab ===
        "questions" &&
        renderQuestionsTab()}
    </div>
  );
}
export default ImportWord;