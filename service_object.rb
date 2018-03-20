# assess_unpaid_invoice.rb
module AccountService
  class AssessUnpaidInvoice
    include Service

    def self.run_all
      eligible_accounts.each do |account|
        call(account)
      end
    end

    def self.eligible_accounts
      Account.with_invoice_billing
    end

    def initialize(account)
      @account = account
    end

    def call
      invoices = @account.chargify_invoices

      return unless invoices.any?

      most_recent_invoice = invoices.first

      @account.update_setting(:has_unpaid_invoice, true) if
        unpaid(most_recent_invoice) && overdue(most_recent_invoice)
    end

    private

    def unpaid(invoice)
      invoice.state.in?(%w[unpaid partial])
    end

    def overdue(invoice)
      invoice.created_at <= 11.days.ago
    end
  end
end

################################## test ########################################
# assess_unpaid_invoice_test.rb
require "test_helper"

class AccountService::AssessUnpaidInvoiceTest < ActiveSupport::TestCase
  setup do
    @account = FactoryGirl.create(:account)
    @account.payment_method_invoice!
  end

  def service
    AccountService::AssessUnpaidInvoice
  end

  test "an account must have a payment method of invoice to be eligible" do
    assert_equal [@account], service.eligible_accounts
    @account.payment_method_card!
    assert_equal [], service.eligible_accounts
  end

  test "run_all updates multiple eligibale accounts" do
    account2 = FactoryGirl.create(:account, id: 2)
    account2.payment_method_invoice!

    account3 = FactoryGirl.create(:account, id: 3)
    account3.payment_method_card!

    Chargify::Invoice.expects(:find_by_subscription_id).twice
      .returns(mock_invoices("paid", "unpaid"))

    service.run_all

    assert_equal true, @account.reload.has_unpaid_invoice?
    assert_equal true, account2.reload.has_unpaid_invoice?
    assert_equal false, account3.reload.has_unpaid_invoice?
  end

  test "invoice must be unpaid for 11 days to mark account pastdue" do
    invoice = mock
    invoices = [invoice]
    Chargify::Invoice.expects(:find_by_subscription_id).returns(invoices)

    invoice.stubs(:state).returns("paid")
    invoice.stubs(:created_at).returns(11.days.ago)
    service.call(@account)
    assert_equal false, @account.has_unpaid_invoice?

    invoice.stubs(:state).returns("unpaid")
    invoice.stubs(:created_at).returns(10.days.ago)
    service.call(@account)
    assert_equal false, @account.has_unpaid_invoice?

    invoice.stubs(:state).returns("unpaid")
    invoice.stubs(:created_at).returns(11.days.ago)
    service.call(@account)
    assert_equal true, @account.has_unpaid_invoice?
  end

  test "only the most recent, unpaid invoice will be considered" do
    invoices = mock_invoices("unpaid", "paid")

    Chargify::Invoice.expects(:find_by_subscription_id).returns(invoices)
    service.call(@account)
    assert_equal false, @account.has_unpaid_invoice?

    invoice3 = mock
    invoice3.stubs(:state).returns("unpaid")
    invoice3.stubs(:created_at).returns(11.days.ago)
    invoices.unshift invoice3

    service.call(@account)
    assert_equal true, @account.has_unpaid_invoice?
  end

  def mock_invoices(state1, state2)
    invoice1 = mock
    invoice1.stubs(:state).returns(state1)
    invoice1.stubs(:created_at).returns(41.days.ago)

    invoice2 = mock
    invoice2.stubs(:state).returns(state2)
    invoice2.stubs(:created_at).returns(21.days.ago)

    [invoice2, invoice1]
  end
end
