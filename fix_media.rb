
require 'fileutils'

def bad_file?(filename)
    ext = File.extname(filename)
    if ext.downcase == '.wav'
        `ffprobe -hide_banner -loglevel panic -show_entries stream=codec_name "#{filename}"`.match(/^codec_name=\w+$/){|c|
            return c[0] =~ /pcm_f32le/ if c
        }
        elsif ext.downcase == '.png'
        info = `identify -verbose "#{filename}"`
        ctype = info.match(/png:IHDR\.color_type:.+/)
        return (ctype[0] =~ /Grayscale/ || ctype[0] =~ /Indexed/) if ctype
    end
    return false
end

def list_files(dir)
    ret = []
    d = Dir["#{dir}/*"]
    d.sort.each{|path|
        # using full-width '%' to stop printf from exploding
        printf("Scanning #{path.sub('%','％')} .. ")
        if File.file?(path) && bad_file?(path)
            ret << path
            printf "(MARKED)"
            elsif File.directory?(path)
            printf("\n")
            ret |= list_files(path)
        end
        printf("\n")
    }
    return ret
end

def convert_file(src, dest)
    ext = File.extname(src)
    if ext.downcase == '.wav'
        `ffmpeg -hide_banner -loglevel panic -y -i "#{src}" "#{dest}"`
        elsif ext.downcase == '.png'
        FileUtils.rm_f(dest) if File.exist?(dest)
        `convert -define png:format=png32 "#{src}" "#{dest}"`
    end
    return File.exist?(dest)
end

def main
    # Villains of the day
    evil_audio  = Dir.exist?('Audio') ? list_files('Audio') : []
    evil_images = Dir.exist?('Graphics') ? list_files('Graphics') : []
    puts sprintf("WAV files: %04d",evil_audio.length)
    puts sprintf("PNG files: %04d",evil_images.length)
    puts sprintf("TOTAL    : %04d",evil_audio.length+evil_images.length)
    files = [evil_audio, evil_images].flatten
    files.length.times{|i|
        dest_dir = File.dirname('Converted_'+files[i].sub(/^\.\//, ''))
        FileUtils.mkdir_p(dest_dir) if !Dir.exist?(dest_dir)
        puts sprintf("(%04d/%04d, %03d％) Converting %s ..",
                     (i+1), files.length, (((i+1).to_f / files.length) * 100).round, files[i])
                     rc = convert_file(files[i], File.join(dest_dir, File.basename(files[i])))
                     raise(RuntimeError, "Failed to convert #{files[i]}") if !rc
    }
    puts "Done!"
end
main