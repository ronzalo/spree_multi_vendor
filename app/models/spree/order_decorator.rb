module Spree::OrderDecorator
  def self.prepended(base)
    base.has_many :commissions, class_name: 'Spree::OrderCommission'
    base.state_machine.after_transition to: :complete, do: :generate_order_commissions
    base.state_machine.after_transition to: :complete, do: :send_notification_mails_to_vendors
  end

  def generate_order_commissions
    Spree::Orders::GenerateCommissions.call(self)
  end

  def vendor_line_items(vendor)
    line_items.for_vendor(vendor)
  end

  def vendor_shipments(vendor)
    shipments.for_vendor(vendor)
  end

  def vendor_ship_total(vendor)
    vendor_shipments(vendor).sum(&:final_price)
  end

  def display_vendor_ship_total(vendor)
    Spree::Money.new(vendor_ship_total(vendor), { currency: currency })
  end

  def vendor_subtotal(vendor)
    vendor_line_items(vendor).sum(:pre_tax_amount)
  end

  def display_vendor_subtotal(vendor)
    Spree::Money.new(vendor_subtotal(vendor), { currency: currency })
  end

  def vendor_promo_total(vendor)
    vendor_line_items(vendor).sum(:promo_total)
  end

  def display_vendor_promo_total(vendor)
    Spree::Money.new(vendor_promo_total(vendor), { currency: currency })
  end

  def vendor_additional_tax_total(vendor)
    vendor_line_items(vendor).sum(:additional_tax_total)
  end

  def display_vendor_additional_tax_total(vendor)
    Spree::Money.new(vendor_additional_tax_total(vendor), { currency: currency })
  end

  def vendor_included_tax_total(vendor)
    vendor_line_items(vendor).sum(:included_tax_total)
  end

  def display_vendor_included_tax_total(vendor)
    Spree::Money.new(vendor_included_tax_total(vendor), { currency: currency })
  end

  def vendor_item_count(vendor)
    vendor_line_items(vendor).sum(:quantity)
  end

  def vendor_total(vendor)
    vendor_line_items(vendor).sum(&:total) + vendor_ship_total(vendor)
  end

  def display_vendor_total(vendor)
    Spree::Money.new(vendor_total(vendor), { currency: currency })
  end

  def display_order_commission
    Spree::Money.new(commissions.sum(:amount), { currency: currency })
  end

  def display_vendor_commission(vendor)
    Spree::Money.new(vendor_commission(vendor), { currency: currency })
  end

  def vendor_commission(vendor)
    commissions.for_vendor(vendor).sum(:amount)
  end

  def send_notification_mails_to_vendors
    vendor_ids.each do |vendor_id|
      Spree::VendorMailer.vendor_notification_email(id, vendor_id).deliver_later
    end
  end

  # we're leaving this on purpose so it can be easily modified to fit desired scenario
  # eg. scenario A - vendorized products, scenario B - vendorized variants of the same product
  def vendor_ids
    line_items.map { |line_item| line_item.product.vendor_id }.uniq
  end
end

Spree::Order.prepend Spree::OrderDecorator
