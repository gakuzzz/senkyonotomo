require "nkf"
require "csv"
class HomesController < BaseController
  def index
  end


  def create_csv

    # Wix一般・予約
    if params[:wix_general].present? || params[:wix_reservation].present?

      @results = []
      if params[:wix_general].present?
        @results += wix_data(params[:wix_general])
      end

      if params[:wix_reservation].present?
        @results += wix_data(params[:wix_reservation])
      end

      respond_to do |format|
        format.csv do
          send_data render_to_string, filename: "hoge.csv", type: 'text/csv; charset=shift_jis'
        end
      end

    end
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

  # 一般書籍
  #<CSV::Row
  # "﻿Order #":"10043"
  # "Date":"Nov 24, 2018"
  # "Time":"11:30:56 AM"
  # "Billing Customer":"佐伯 加寿美"
  # "Billing Company Name":""
  # "Billing Country":"JPN"
  # "Billing State":"JP-11"
  # "Billing City":"東松山市箭弓町"
  # "Billing Street Name&Number":"2-11-11-101"
  # "Billing Zip Code":"\"355-0028\""
  # "Delivery Customer":"佐伯 加寿美"
  # "Delivery Company Name":""
  # "Delivery Country":"JPN"
  # "Delivery State":"JP-11"
  # "Delivery City":"東松山市箭弓町"
  # "Delivery Street Name&Number":"2-11-11-101"
  # "Delivery Zip Code":"\"355-0028\""
  # "Buyer"s Phone #":"\"0493534341\""
  # "Shipping Label":"佐伯 加寿美 / 2-11-11-101 / 東松山市箭弓町 / JP-11  355-0028 / JPN / 0493534341"
  # "Buyer"s Email":"kazumi_saeki@yahoo.co.jp"
  # "Delivery Method":"通常配送 "
  # "Item"s Name":"『フルカラー図解 地方選挙必勝の手引』【書籍版】"
  # "Item"s Variant":""
  # "SKU":"1923031110007"
  # "Qty":"1"
  # "Item"s Price":"11000.0"
  # "Item"s Weight":"1.0"
  # "Item"s Custom Text":""
  # "Coupon":""
  # "Notes to Seller":""
  # "Shipping":"600.0"
  # "Tax":"880.0"
  # "Total":"12480.0"
  # "Currency":"JPY"
  # "Payment Method":"Stripe"
  # "Payment":"paid"
  # "Fulfillment":"fulfilled">
  def wix_data(file)

    encoding = "Shift_JIS:UTF-8"
    encode = NKF.guess(File.read(file.path)).name
    if encode == "UTF-8"
      encoding = "UTF-8"
    end

    result = []
    count = 1
    CSV.foreach(file.path, encoding: encoding, headers: true) do |row|
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
      info[:order_number] = "snky-" + day.to_s + count.to_s
      info[:date] = billing_date
      info[:settlement_code] = "55"
      info[:settlement_section] = "14"
      info[:zip_code] = row["Delivery Zip Code"].gsub!(/\"/, '').gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
      info[:prefecture] = prefecture
      info[:address1] = (prefecture + row["Delivery City"].to_s + row["Delivery Street Name&Number"].to_s).gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "").sjisable
      info[:address2] = ""
      info[:campany] = ""
      info[:name] = row["Delivery Customer"].gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
      info[:kana_name] = ""
      info[:tel] = row["Buyer's Phone #"].gsub!(/\"/, '')
      info[:email] = row["Buyer's Email"].gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
      info[:product_total_price] = row["Item's Price"]
      info[:fee] = "0"
      info[:delivery_fee] = row["Shipping"]
      info[:total_price] = row["Total"]
      info[:site_code] = "snky"
      info[:remarks] = ""
      info[:delvery_time] = ""
      info[:delvery_date] = ""
      info[:delivery_section] = "08"
      info[:stock_section] = "01"
      info[:product_code] = "9784909687005"
      info[:product_name] = row["Item's Name"].gsub(/[\xe2\x80\x8b]+/, '').gsub(" ", "")
      info[:price] = row["Item's Price"]
      info[:amount] = row["Qty"]
      info[:detail_price] = row["Item's Price"]

      count += 1
      result << info
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
end
