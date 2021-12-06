namespace TextPieces {

    struct ScriptResult {
        string stdout;
        string stderr;
    }

    class Tool : Object {
        public static string CUSTOM_TOOLS_DIR;
        public static bool   in_flatpak;

        public string name { get; set; }
        public string translated_name {
            get {
                return _(name);
            }
        }
        public string description { get; set; }
        public string translated_description {
            get {
                return _(description);
            }
        }

        public string[] arguments;

        public string icon = "applications-utilities-symbolic";
        public string script;
        public bool   is_system;

        static construct {
            CUSTOM_TOOLS_DIR = Path.build_filename (
                Environment.get_home_dir (), ".local", "share", "textpieces", "scripts"
            );

            var tools_dir = File.new_for_path (CUSTOM_TOOLS_DIR);

            try {
                if (!tools_dir.query_exists ())
                    tools_dir.make_directory_with_parents ();
            } catch (Error e) {
                critical ("Can't create script directory: %s", e.message);
            }

            in_flatpak = File.new_for_path ("/.flatpak-info").query_exists (null);
        }

        public ScriptResult apply (string input, string[] args) {
            var scriptdir = is_system
                ? Config.SCRIPTDIR
                : CUSTOM_TOOLS_DIR;

            string[] cmdline = {};
            if (!is_system && in_flatpak) {
                cmdline += "flatpak-spawn";
                cmdline += "--host";
            }
            cmdline += Path.build_filename (scriptdir, script);

            foreach (var arg in args)
                cmdline += arg;

            try {
                var process = new Subprocess.newv (
                    cmdline,
                    STDIN_PIPE  |
                    STDOUT_PIPE |
                    STDERR_PIPE
                );

                string stdout;
                string stderr;
                process.communicate_utf8 (input, null, out stdout, out stderr);

                bool success = process.get_successful ();

                return {
                    success
                        ? stdout
                        : null,
                    (stderr ?? "") != ""
                        ? stderr
                        : null
                };
            } catch (Error e) {
                message ("INTERNAL ERROR");
                return {
                    e.message,
                    null
                };
            }
        }

        public void open (Gtk.Window? window = null)
            requires (!this.is_system)
        {
            Utils.open_file.begin (
                File.new_build_filename (
                    Tool.CUSTOM_TOOLS_DIR, this.script
                ),
                window
            );
        }

        public static string generate_filename (string name) {
            /* Generate salt */
            var salt = Checksum.compute_for_string (
                SHA256,
                Random.next_int  ()
                      .to_string ()
            ).slice (0, 8);

            /* Generate filename in form:
               "filename-salt", where salt
               is eight random characters */
            return "%s-%s".printf (
                name.down ()
                    .replace (" ", "_")
                    .replace ("?", "x"),
                salt
            );
        }
    }

    Gtk.Widget build_list_row (Object item) {
        var tool = (Tool) item;

        return new Adw.ActionRow () {
            title = tool.translated_name,
            subtitle = tool.translated_description,
            icon_name = tool.icon,
            activatable = true
        };
    }
}
