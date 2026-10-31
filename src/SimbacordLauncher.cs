// SimbacordLauncher - check GitHub release, update if needed, launch Simbacord
// Point d entree a la place de Simbacord.exe directement.
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading;

[assembly: AssemblyTitle("Simbacord Launcher")]
[assembly: AssemblyProduct("Simbacord")]
[assembly: AssemblyVersion("1.0.0.0")]

static class SimbacordLauncher
{
    const string REPO = "wluyzz/SimbaCord";
    const string ASSET_NAME = "simbacordsetup.exe";
    const string API = "https://api.github.com/repos/" + REPO + "/releases/latest";
    const int DOWNLOAD_TIMEOUT_MS = 120000;
    const int INSTALL_TIMEOUT_MS = 300000;

    static string InstallDir { get { return AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\'); } }
    static string SimbacordExe { get { return Path.Combine(InstallDir, "Simbacord.exe"); } }
    static string VersionFile { get { return Path.Combine(InstallDir, "version.txt"); } }

    [STAThread]
    static int Main(string[] args)
    {
        bool updated = false;
        try { updated = TryUpdate(); }
        catch { /* best effort - update ne doit jamais bloquer le launch */ }

        // Si on vient d appliquer un update, l installer vient de reecrire les fichiers.
        // On relance Simbacord.exe depuis le chemin fixe - les nouveaux fichiers sont deja la.
        LaunchSimbacord();
        return 0;
    }

    static bool TryUpdate()
    {
        if (!File.Exists(VersionFile)) return false;
        string local = SafeRead(VersionFile).Trim();
        if (string.IsNullOrEmpty(local)) return false;

        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
        ServicePointManager.DefaultConnectionLimit = 10;

        string json;
        try { json = Http(API); }
        catch { return false; }

        string remote = Extract(json, "\"tag_name\"");
        if (string.IsNullOrEmpty(remote)) return false;
        remote = remote.TrimStart('v', 'V');
        string localNorm = local.TrimStart('v', 'V');
        if (string.Equals(remote, localNorm, StringComparison.OrdinalIgnoreCase)) return false;

        string dlUrl = ExtractAssetUrl(json, ASSET_NAME);
        if (string.IsNullOrEmpty(dlUrl)) return false;

        string tmp = Path.Combine(Path.GetTempPath(), "simbacordsetup_" + Sanitize(remote) + ".exe");
        try { if (File.Exists(tmp)) File.Delete(tmp); } catch { }

        long expected = 0;
        try { Download(dlUrl, tmp, out expected); }
        catch { TryDelete(tmp); return false; }

        // Verif integrite basique : taille locale == Content-Length si fourni
        try
        {
            var fi = new FileInfo(tmp);
            if (!fi.Exists || fi.Length == 0) { TryDelete(tmp); return false; }
            if (expected > 0 && fi.Length != expected) { TryDelete(tmp); return false; }
        }
        catch { TryDelete(tmp); return false; }

        // Lance installer silencieux et attend sa fin (sinon on racerait avec Simbacord.exe launch).
        try
        {
            var psi = new ProcessStartInfo(tmp, "/S")
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
                WorkingDirectory = Path.GetTempPath()
            };
            var p = Process.Start(psi);
            if (p == null) return false;
            if (!p.WaitForExit(INSTALL_TIMEOUT_MS))
            {
                try { p.Kill(); } catch { }
                return false;
            }
            TryDelete(tmp);
            return true;
        }
        catch { TryDelete(tmp); return false; }
    }

    static void LaunchSimbacord()
    {
        if (!File.Exists(SimbacordExe)) return;
        try
        {
            var psi = new ProcessStartInfo(SimbacordExe)
            {
                UseShellExecute = false,
                WorkingDirectory = InstallDir
            };
            Process.Start(psi);
        }
        catch { }
    }

    static string SafeRead(string path)
    {
        try { return File.ReadAllText(path); } catch { return ""; }
    }

    static void TryDelete(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); } catch { }
    }

    static string Sanitize(string s)
    {
        var sb = new StringBuilder();
        foreach (char c in s)
            sb.Append(char.IsLetterOrDigit(c) || c == '.' || c == '-' || c == '_' ? c : '_');
        return sb.ToString();
    }

    static string Http(string url)
    {
        var req = (HttpWebRequest)WebRequest.Create(url);
        req.UserAgent = "SimbacordLauncher";
        req.Timeout = 10000;
        req.ReadWriteTimeout = 10000;
        req.Accept = "application/vnd.github+json";
        using (var resp = (HttpWebResponse)req.GetResponse())
        {
            if ((int)resp.StatusCode >= 400) throw new WebException("HTTP " + (int)resp.StatusCode);
            using (var sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
                return sr.ReadToEnd();
        }
    }

    static void Download(string url, string dest, out long contentLength)
    {
        contentLength = 0;
        var req = (HttpWebRequest)WebRequest.Create(url);
        req.UserAgent = "SimbacordLauncher";
        req.AllowAutoRedirect = true;
        req.Timeout = 20000;
        req.ReadWriteTimeout = DOWNLOAD_TIMEOUT_MS;
        req.Accept = "application/octet-stream";
        using (var resp = (HttpWebResponse)req.GetResponse())
        {
            if ((int)resp.StatusCode >= 400) throw new WebException("HTTP " + (int)resp.StatusCode);
            contentLength = resp.ContentLength;
            using (var rs = resp.GetResponseStream())
            using (var fs = File.Create(dest))
            {
                byte[] buf = new byte[65536];
                int n;
                while ((n = rs.Read(buf, 0, buf.Length)) > 0) fs.Write(buf, 0, n);
                fs.Flush();
            }
        }
    }

    // Mini-parser JSON juste assez pour tag_name et le bon asset
    static string Extract(string json, string key)
    {
        int i = json.IndexOf(key);
        if (i < 0) return null;
        int colon = json.IndexOf(':', i);
        if (colon < 0) return null;
        int q1 = json.IndexOf('"', colon + 1);
        if (q1 < 0) return null;
        int q2 = json.IndexOf('"', q1 + 1);
        if (q2 < 0) return null;
        return json.Substring(q1 + 1, q2 - q1 - 1);
    }

    static string ExtractAssetUrl(string json, string assetName)
    {
        int idx = 0;
        while (idx < json.Length)
        {
            int nameAt = json.IndexOf("\"name\"", idx);
            if (nameAt < 0) return null;
            int q1 = json.IndexOf('"', nameAt + 6);
            if (q1 < 0) return null;
            int q2 = json.IndexOf('"', q1 + 1);
            if (q2 < 0) return null;
            string nm = json.Substring(q1 + 1, q2 - q1 - 1);
            if (string.Equals(nm, assetName, StringComparison.OrdinalIgnoreCase))
            {
                int urlAt = json.IndexOf("\"browser_download_url\"", q2);
                if (urlAt < 0) return null;
                int u1 = json.IndexOf('"', urlAt + 22);
                if (u1 < 0) return null;
                int u2 = json.IndexOf('"', u1 + 1);
                if (u2 < 0) return null;
                return json.Substring(u1 + 1, u2 - u1 - 1);
            }
            idx = q2 + 1;
        }
        return null;
    }
}
