defmodule SinghSabha.Payments do
  alias Stripe.Checkout.Session

  def create_checkout_session(event) do
    base_url = SinghSabhaWeb.Endpoint.url()

    unit_amount_cents =
      event.event_type.deposit
      |> Decimal.mult(100)
      |> Decimal.to_integer()

    params = %{
      payment_method_types: [:card],
      mode: :payment,
      customer_email: event.registrant_email,
      metadata: %{
        event_id: to_string(event.id)
      },
      line_items: [
        %{
          price_data: %{
            currency: "cad",
            product_data: %{
              name: "#{event.event_type.display_name} Booking Deposit"
            },
            unit_amount: unit_amount_cents
          },
          quantity: 1
        }
      ],
      success_url:
        "#{base_url}/payment/success?session_id={CHECKOUT_SESSION_ID}&event_id=#{event.id}",
      cancel_url:
        "#{base_url}/payment/cancel?session_id={CHECKOUT_SESSION_ID}&event_id=#{event.id}"
    }

    Session.create(params)
  end

  def validate_session(session_id) do
    with {:ok, session} <- Session.retrieve(session_id),
         true <- session.payment_status == "paid" do
      {:ok, session}
    else
      false -> {:error, "Payment not successful"}
      error -> error
    end
  end
end
