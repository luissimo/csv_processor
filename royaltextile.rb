$OUTPUT_FOLDER = "royaltextile"
$FEED_URL = "https://www.royaltextile.nl/en/feed/assortmentfeeddownload.aspx?language=nl"

class CreateFeed
  require 'net/http'
  require 'smarter_csv'
  require 'colorize'
  require 'csv'

  TIMESTAMP = Time.new.to_i.freeze

  def initialize
    # download file
    download = Net::HTTP.get_response(URI.parse($FEED_URL))
    puts 'Download completed'.green

    # save downloaded file
    File.open("royaltextile_#{TIMESTAMP}.csv" ,'w') do |f|
      f.write download.body
      puts "File --royaltextile_#{TIMESTAMP}.csv-- saved".green
    end
  end

  def process_rows
    @@data = SmarterCSV.process("royaltextile_#{TIMESTAMP}.csv", {col_sep: ';'})

    # process rows
    rows_parsed = 0
    @@data.each do |row|
      rows_parsed += 1

      delete_hash_rows(row)
      case row[:verwachte_leverweek]
      when 'Uitverkocht en komt ook niet meer binnen'
        empty_hash_values(row)
      when "Nader te bepalen"
        empty_hash_values(row)
      end

      case row[:op_voorraad]
      when 'N'
        empty_hash_values(row)
      end

      price = row[:adviesprijs].gsub(",", ".").to_f + 10.00 if row[:adviesprijs]
      row[:adviesprijs] = price if price
    end
    puts "#{rows_parsed} rows processed".green
  end

  def save_processed_rows
    # save processed rows
    column_names = @@data.first.keys
    CSV.open("royaltextile_#{TIMESTAMP}.csv", "w") do |current_csv|
      current_csv << column_names
      @@data.each do |new_rows|
        current_csv << new_rows.values
      end
    end
    puts "Processed file --royaltextile_#{TIMESTAMP}.csv-- saved".green
  end

  private

  def empty_hash_values(hash)
    hash.each { |k, v| hash[k] = nil }
  end

  def delete_hash_rows(hash)
    hash.each { |k, v| hash.delete(k) if unused_rows.include?(k) }
  end

  def unused_rows
    # delete these rows from csv
    [:kleur, :maat, :merknaam, :sku, :afbeelding1, :categorie_1, :uitlopend, :subgroep, :materiaal,
     :kg_piece, :groupcode, :groupdescription, :groupvalue, :dooseenheid, :image, :invoerdatum,
     :wijzigingsdatum, :prioriteit, :preorder_artikel, :stuk_eenheid, :pallet_eenheid, :extra,
     :web_img_thumb, :web_img_mid, :web_img_large, :print_img_original, :"g.w._export_carton"]
  end
end

Dir.chdir($OUTPUT_FOLDER) do
  file = CreateFeed.new
  file.process_rows
  file.save_processed_rows
end
