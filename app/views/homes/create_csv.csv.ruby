require 'csv'

CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|

  column_names = %w(注文番号 受注日 決済コード 受注区分 郵便番号 都道府県名 住所1 住所2 送付先会社名 送付先名 送付先名前ふりがな 送付先電話番号 e_mail 商品合計購入金額 決済手数料 発送手数料 お支払い合計金額 サイトコード 備考欄 時間帯指定 必着日 発送区方法 在庫区分 商品コード 商品名 販売単価 数量 明細金額)
  csv << column_names

  @results.each do |result|
    column_values = [
      result[:order_number],
      result[:date],
      result[:settlement_code],
      result[:settlement_section],
      result[:zip_code],
      result[:prefecture],
      result[:address1],
      result[:address2],
      result[:campany],
      result[:name],
      result[:kana_name],
      '="' + result[:tel] + '"',
      result[:email],
      result[:product_total_price],
      result[:fee],
      result[:delivery_fee],
      result[:total_price],
      result[:site_code],
      result[:remarks],
      result[:delvery_time],
      result[:delvery_date],
      '="' + result[:delivery_section] + '"',
      '="' + result[:stock_section] + '"',
      '="' + result[:product_code] + '"',
      result[:product_name],
      result[:price],
      result[:amount],
      result[:detail_price]
    ]
    csv << column_values
  end
end
