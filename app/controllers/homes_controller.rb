require "nkf"
require "csv"
class HomesController < BaseController
  def index
  end


  def create_csv
    if params[:publish_date].blank?
      return redirect_to root_path, alert: "出荷日を入力してください"
    end


    @results = []
    # Wix一般・予約
    if params[:wix_general].present? || params[:wix_reservation].present?
      if params[:wix_general].present?
        @results += wix_data(params[:wix_general], params[:publish_date])
      end

      if params[:wix_reservation].present?
        @results += wix_data(params[:wix_reservation], params[:publish_date])
      end
    end

    if params[:easypay_all].present?
      @results += easypay_data(params[:easypay_all], params[:publish_date])
    end

    # amazon
    if params[:amazon_general].present?
      @results += amazon_data(params[:amazon_general], params[:publish_date])
    end

    if @results.blank?
      return redirect_to root_path, alert: "販売データがセットされていません"
    end

    respond_to do |format|
      format.csv do
        send_data render_to_string, filename: "出荷用データ_#{Time.now.to_date.to_s}.csv", type: 'text/csv; charset=shift_jis'
      end
    end

    cookies[:dialogue_exported] = { value: 'yes', expires: 1.minutes.from_now  }
  end

  def amazon_data(file, publish_date)
    encoding = "Shift_JIS:UTF-8"
    encode = NKF.guess(File.read(file.path)).name
    if encode == "UTF-8"
      encoding = "UTF-8"
    end
    result = []
    count = 1

    p_date = publish_date.split("/")
    publish_date_str = p_date[1] + p_date[2]

    CSV.foreach(file.path, encoding: encoding, col_sep: "\t", headers: true) do |row|
      begin

        info = {}
        # 配送会社に渡す情報必要な情報
        order_id      = row["order-id"]
        order_item_id = row["order-item-id"]
        purchase_date = row["purchase-date"]
        payments_date = row["payments-date"]
        buyer_email   = row["buyer-email"]
        buyer_name    = row["buyer-name"]
        buyer_phone_number = row["buyer-phone-number"]
        sku           = row["sku"]
        product_name  = row["product-name"]
        quantity_purchased = row["quantity-purchased"]
        currency = row["currency"]
        item_price = row["item-price"]
        item_tax = row["item-tax"]
        shipping_price = row["shipping-price"]
        shipping_tax = row["shipping-tax"]
        ship_service_level = row["ship-service-level"]
        recipient_name = row["recipient-name"]
        ship_address_1 = row["ship-address-1"]
        ship_address_2 = row["ship-address-2"]
        ship_address_3 = row["ship-address-3"]
        ship_city = row["ship-city"]
        ship_state = row["ship-state"]
        ship_postal_code = row["ship-postal-code"]
        ship_country = row["ship-country"]
        ship_phone_number = row["ship-phone-number"]
        delivery_start_date = row["delivery-start-date"]
        delivery_end_date = row["delivery-end-date"]
        delivery_time_zone = row["delivery-time-zone"]
        delivery_Instructions = row["delivery-Instructions"]

        address1 = ship_address_1.to_s + ship_address_2.to_s + ship_address_3.to_s
        logger.debug(address1)

        date = Date.strptime(purchase_date, '%Y-%m-%dT%H:%M:%S%z')
        billing_date = date.strftime("%Y/%m/%d")


        info[:order_number] = "snky-" + publish_date_str + "-" + sprintf("%03d", count.to_s)
        info[:date] = billing_date
        info[:settlement_code] = "55"
        info[:settlement_section] = "14"
        info[:zip_code] = zip_code(ship_postal_code)
        info[:prefecture] = ship_state
        info[:address1] = address1.gsub("−", "-")
        info[:address2] = ""
        info[:campany] = ""
        info[:name] = buyer_name
        info[:kana_name] = "　"
        info[:tel] = phone_number(buyer_phone_number.to_s)
        info[:email] = buyer_email
        info[:product_total_price] = item_price.to_s
        info[:fee] = "0"
        info[:delivery_fee] = "600"
        info[:total_price] = (item_price.to_i + 600).to_s
        info[:site_code] = "snky"
        info[:remarks] = ""
        info[:delvery_time] = ""
        info[:delvery_date] = ""
        info[:delivery_section] = quantity_purchased == "1" ? "08" : "06"
        info[:stock_section] = "01"
        info[:product_code] = sku
        info[:product_name] = product_name
        info[:price] = item_price.to_s
        info[:amount] = quantity_purchased
        info[:detail_price] = item_price.to_s

        count += 1
        result << info
      rescue
        raise $!, "amazon住所データの #{count} 行目を処理中にエラーが発生しました。\n#{$!.message}", $!.backtrace
      end
    end
    result
  end


  def easypay_data(file, publish_date)
    encoding = "Shift_JIS:UTF-8"
    encode = NKF.guess(File.read(file.path)).name
    if encode == "UTF-8"
      encoding = "UTF-8"
    end
    result = []
    count = 1

    p_date = publish_date.split("/")
    publish_date_str = p_date[1] + p_date[2]

    CSV.foreach(file.path, encoding: encoding, headers: true) do |row|
      begin

        info = {}
        # 配送会社に渡す情報必要な情報
        info[:order_number] = "snky-" + publish_date_str + "-" + sprintf("%03d", count.to_s)
        info[:date] = row["注文日時"]
        info[:settlement_code] = "55"
        info[:settlement_section] = "14"
        info[:zip_code] = "住所はwixの情報と照らし合わせて入力してください"
        info[:prefecture] = ""
        info[:address1] = ""
        info[:address2] = ""
        info[:campany] = ""
        info[:name] = row["購入者名"]
        info[:kana_name] = "　"
        info[:tel] = ""
        info[:email] = row["購入者メールアドレス"]
        info[:product_total_price] = easypay_no_fee_price(row["金額"])
        info[:fee] = "0"
        info[:delivery_fee] = "600"
        info[:total_price] = row["金額"]
        info[:site_code] = "snky"
        info[:remarks] = ""
        info[:delvery_time] = ""
        info[:delvery_date] = ""
        info[:delivery_section] = "08"
        info[:stock_section] = "01"
        info[:product_code] = "9784909687005"
        info[:product_name] = "『フルカラー図解 地方選挙必勝の手引』"
        info[:price] = easypay_no_fee_price(row["金額"])
        info[:amount] = "1"
        info[:detail_price] = easypay_no_fee_price(row["金額"])

        if row["金額"] == "17663" || row["金額"] == "14000"
          count += 1
          result << info
        end

      rescue
        binding.pry
        raise $!, "easypayの #{count} 行目を処理中にエラーが発生しました。\n#{$!.message}", $!.backtrace
      end
    end
    result
  end

  # 発送手数料、消費税抜き金額
  def easypay_no_fee_price(price)
    # 【セット版】一般
    return "15800" if price == "17663"

    # 【セット版】紹介販売
    return "14000" if price == "14000"

    return 0

  end


  # Wixのデータを取得
  def wix_data(file, publish_date)
    encoding = "Shift_JIS:UTF-8"
    encode = NKF.guess(File.read(file.path)).name
    if encode == "UTF-8"
      encoding = "UTF-8"
    end

    p_date = publish_date.split("/")
    publish_date_str = p_date[1] + p_date[2]

    result = []
    count = 1
    CSV.foreach(file.path, encoding: encoding, headers: true) do |row|

      begin
        info = {}
        info[:wix_order_number] = row["Order #"]

        date = Date.strptime(row["Date"], "%b %d, %Y")
        billing_date = date.strftime("%Y/%m/%d")
        day = date.strftime("%m%d")

        prefecture = row["Delivery State"]
        if prefecture.start_with?("JP-")
          prefecture = prefecture_name(row["Delivery State"])
        end

        # 配送会社に渡す情報必要な情報
        info[:order_number] = "snky-" + publish_date_str + "-" + sprintf("%03d", count.to_s)
        info[:date] = billing_date
        info[:settlement_code] = "55"
        info[:settlement_section] = "14"
        info[:zip_code] = zip_code(row["Delivery Zip Code"].gsub!(/\"/, '').gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", ""))
        info[:prefecture] = prefecture
        info[:address1] = (prefecture + row["Delivery City"].to_s + row["Delivery Street Name&Number"].to_s).gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "").sjisable
        info[:address2] = ""
        info[:campany] = ""
        info[:name] = row["Delivery Customer"].gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
        info[:kana_name] = "　"
        info[:tel] = phone_number(row["Buyer's Phone #"].gsub!(/\"/, ''))
        info[:email] = row["Buyer's Email"].gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
        info[:product_total_price] = row["Item's Price"]
        info[:fee] = "0"
        info[:delivery_fee] = row["Shipping"]
        info[:total_price] = row["Total"]
        info[:site_code] = "snky"
        info[:remarks] = ""
        info[:delvery_time] = ""
        info[:delvery_date] = ""
        info[:delivery_section] = row["Qty"] == "1" ? "08" : "06"
        info[:stock_section] = "01"
        info[:product_code] = "9784909687005"
        info[:product_name] = row["Item's Name"].gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
        info[:price] = row["Item's Price"]
        info[:amount] = row["Qty"]
        info[:detail_price] = row["Item's Price"]

        count += 1
        result << info
      rescue
        raise $!, "wixの #{count} 行目を処理中にエラーが発生しました。\n#{$!.message}", $!.backtrace
      end

# 注文番号 : snky-1126-001
# 受注日 : 2018/11/26
# 決済コード : 55[fix]
# 受注区分 : 14[fix]
# 郵便番号 : 166-0003
# 都道府県名 : 東京都
# 住所1:杉並区高円寺南5-22-4-202
# 住所2: -
# 送付先会社名: -
# 送付先名:樋脇 岳
# 送付先名前ふりがな: -
# 送付先電話番号:09022223333
# e_mail:gakusss@gmail.com
# 商品合計購入金額:17063
# 決済手数料:0[fix]
# 発送手数料:600
# お支払い合計金額:17663(商品合計購入金額 + 発送手数料)
# サイトコード:snky[fix]
# 備考欄: -
# 時間帯指定: -
# 必着日: -
# 発送区方法:08[fix]
# 在庫区分:01[fix]
# 商品コード:9784909687005[fix]
# 商品名:『フルカラー図解 地方選挙 必勝の手引』
# 販売単価:17063
# 数量:1
# 明細金額:17063
    end
    result
  end

  private

  def zip_code(code)
    zip_code = code.to_s
    unless zip_code.include?("-")
      zip_code = zip_code.insert(3, "-")
    end
    zip_code
  end

  def phone_number(num)
    number = num.strip
    if number.start_with?("+81 ")
      number = number.gsub!("+81 ", "")
    end

    if number.start_with?("+81")
      number = number.gsub!("+81", "")
    end

    unless number.start_with?("0")
      number = "0" + number
    end

    if number.include?("-")
      number = number.gsub!("-", "")
    end
    number
  end

  def prefecture_name(pref_code)
    prefectures = {"JP-01":"北海道","JP-25":"滋賀県",
                   "JP-02":"青森県","JP-26":"京都府",
                   "JP-03":"岩手県","JP-27":"大阪府",
                   "JP-04":"宮城県","JP-28":"兵庫県",
                   "JP-05":"秋田県","JP-29":"奈良県",
                   "JP-06":"山形県","JP-30":"和歌山県",
                   "JP-07":"福島県","JP-31":"鳥取県",
                   "JP-08":"茨城県","JP-32":"島根県",
                   "JP-09":"栃木県","JP-33":"岡山県",
                   "JP-10":"群馬県","JP-34":"広島県",
                   "JP-11":"埼玉県","JP-35":"山口県",
                   "JP-12":"千葉県","JP-36":"徳島県",
                   "JP-13":"東京都","JP-37":"香川県",
                   "JP-14":"神奈川県","JP-38":"愛媛県",
                   "JP-15":"新潟県","JP-39":"高知県",
                   "JP-16":"富山県","JP-40":"福岡県",
                   "JP-17":"石川県","JP-41":"佐賀県",
                   "JP-18":"福井県","JP-42":"長崎県",
                   "JP-19":"山梨県","JP-43":"熊本県",
                   "JP-20":"長野県","JP-44":"大分県",
                   "JP-21":"岐阜県","JP-45":"宮崎県",
                   "JP-22":"静岡県","JP-46":"鹿児島県",
                   "JP-23":"愛知県","JP-47":"沖縄県",
                   "JP-24":"三重県"}
    prefectures[:"#{pref_code}"]
  end
end
