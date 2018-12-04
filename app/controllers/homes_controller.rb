require 'nkf'
require 'csv'
class HomesController < BaseController
  def index
  end


  def create_csv
    if params[:wix_general].present?
      wix_general(params[:wix_general])
    end
  end

  # 一般書籍
  def wix_general(file)
    encoding = "Shift_JIS:UTF-8"
    encode = NKF.guess(File.read(file.path)).name
    if encode == "UTF-8"
      encoding = "UTF-8"
    end

    CSV.foreach(file.path, encoding: encoding, headers: true) do |row|
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
# "Buyer's Phone #":"\"0493534341\""
# "Shipping Label":"佐伯 加寿美 / 2-11-11-101 / 東松山市箭弓町 / JP-11  355-0028 / JPN / 0493534341"
# "Buyer's Email":"kazumi_saeki@yahoo.co.jp"
# "Delivery Method":"通常配送 "
# "Item's Name":"『フルカラー図解 地方選挙必勝の手引』【書籍版】"
# "Item's Variant":""
# "SKU":"1923031110007"
# "Qty":"1"
# "Item's Price":"11000.0"
# "Item's Weight":"1.0"
# "Item's Custom Text":""
# "Coupon":""
# "Notes to Seller":""
# "Shipping":"600.0"
# "Tax":"880.0"
# "Total":"12480.0"
# "Currency":"JPY"
# "Payment Method":"Stripe"
# "Payment":"paid"
# "Fulfillment":"fulfilled">
    end

  end
end
