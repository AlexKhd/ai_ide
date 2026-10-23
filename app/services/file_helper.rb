module FileHelper
  def file_append(filename, text, max_filesize, clear: false)
    # Ensure filename does not contain slashes and is safe
    safe_filename = filename.gsub(/[\/\\]/, '')
    log_dir = Rails.root.join('log')
    log_file_path = log_dir.join("#{safe_filename}.log")

    # Create log directory if it doesn't exist
    FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

    # Clear file if requested
    if clear
      File.open(log_file_path, 'w') { }
    end

    # Check file size and rotate if necessary (skip when clearing)
    if !clear && File.exist?(log_file_path) && File.size(log_file_path) > max_filesize
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      rotated_filename = log_dir.join("#{safe_filename}_#{timestamp}.log")
      File.rename(log_file_path, rotated_filename)
    end

    # Append the text
    timestamped_text = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{text}"

    File.open(log_file_path, 'a') do |file|
      file.puts(timestamped_text)
    end
  end
end
