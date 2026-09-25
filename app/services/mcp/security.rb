# app/services/mcp/security.rb
module Mcp
  module Security
    CRITICAL_BANNED_FILES = %w[.env config/master.key config/credentials.yml.enc config/database.yml].freeze
    CRITICAL_BANNED_DIRS  = %w[.git node_modules log tmp].freeze

    def self.check_path(relative_path)
      return { safe: false, reason: "Missing file path parameter" } if relative_path.blank?

      root_dir = Rails.root.to_s
      full_path = File.expand_path(relative_path, root_dir)

      # 1. Path Traversal Safeguard
      unless full_path.start_with?(root_dir)
        return { safe: false, reason: "Access denied. Cannot access paths outside the project root directory." }
      end

      # 2. Critical Banned Files
      if CRITICAL_BANNED_FILES.include?(File.basename(full_path))
        return { safe: false, reason: "Access denied. File '#{File.basename(full_path)}' contains protected credentials or configuration." }
      end

      # 3. Critical Banned Directories
      CRITICAL_BANNED_DIRS.each do |dir|
        if relative_path.start_with?("#{dir}/") || full_path.include?("/#{dir}/")
          return { safe: false, reason: "Access denied. Directory '#{dir}/' is restricted by security policy." }
        end
      end

      # 4. Gitignore Check
      if gitignored?(relative_path)
        return { safe: false, reason: "Access denied. Path '#{relative_path}' is matched by .gitignore security rules." }
      end

      { safe: true }
    end

    def self.safe_path?(relative_path)
      check_path(relative_path)[:safe]
    end

    private

    def self.gitignored?(relative_path)
      gitignore_path = Rails.root.join(".gitignore")
      return false unless File.exist?(gitignore_path)

      # Normalize path to strip leading slashes
      cleaned_path = relative_path.sub(%r{^/}, '').strip
      ignored = false

      File.foreach(gitignore_path) do |line|
        rule = line.strip
        next if rule.blank? || rule.start_with?("#")

        # Track if the rule is an exception line (starts with !)
        is_exception = rule.start_with?("!")
        rule = rule.sub(/^!/, '') if is_exception

        # Remove leading/trailing slashes for path matching consistency
        rule_clean = rule.sub(%r{^/}, '').sub(%r{/$}, '')

        # Build dynamic glob variations to catch directory blocks vs file targets
        match_patterns = [
          rule_clean,
          "#{rule_clean}/*",
          "**/#{rule_clean}",
          "**/#{rule_clean}/*"
        ]

        pattern_matches = match_patterns.any? do |pattern|
          File.fnmatch?(pattern, cleaned_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end

        if pattern_matches
          # If it matches an exception line, it's explicitly safe. Otherwise, it's blocked.
          ignored = !is_exception
        end
      end

      ignored
    end
  end
end
