class PaymentViewHelper < ViewHelper
  def preview(payment)
    content = h.content_tag(:span, class: "col-md-1") do
      payment_icon(payment)
    end

    klasses = "pp-overview row #{"credit-card" if payment.type == "credit_card"}"

    h.content_tag(:div, class: klasses) do
      content << payment_name(payment)
    end
  end

  private

  def payment_icon(payment)
    case payment.type
    when "credit_card"
      h.concat(h.content_tag(:span, payment.card_type, class: "card-type"))
      h.concat(h.credit_card_icon(payment.card_type))
    when "bank_account"
      h.concat(h.icon('bank'))
      h.concat(h.content_tag(:span, payment.bank_name.truncate(1), class: "card-type"))
    end
  end

  def payment_name(payment)
    text = case payment.type
           when "credit_card"
             payment.masked_card_number
           when "bank_account"
             payment.bank_name
           end

    h.content_tag(:span, text, class: "col-md-11")
  end
end
