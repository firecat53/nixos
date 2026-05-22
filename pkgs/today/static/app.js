if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js", { scope: "/" }).catch(() => {});
  });
}

// Re-focus the entry textarea after returning to the page (mobile keyboard)
const entry = document.getElementById("entry");
if (entry) {
  // Slight delay helps iOS Safari raise the keyboard
  setTimeout(() => entry.focus(), 50);
}
