#!/usr/bin/env ruby
# A realistic customer support chatbot using pattern-ruby.
# Run: ruby -Ilib examples/support_bot.rb

require "pattern_ruby"

# Simulated database
ORDERS = {
  "10001" => { status: "delivered", item: "Ruby Cookbook", date: "2026-03-01" },
  "10002" => { status: "shipped", item: "Mechanical Keyboard", date: "2026-03-05", tracking: "1Z999AA10123456784" },
  "10003" => { status: "processing", item: "USB-C Hub", date: "2026-03-07" },
}

PRODUCTS = {
  "basic" => { price: "$9/mo", features: "5 projects, 1GB storage" },
  "pro" => { price: "$29/mo", features: "Unlimited projects, 50GB storage, priority support" },
  "enterprise" => { price: "$99/mo", features: "Everything in Pro + SSO, audit logs, SLA" },
}

HOURS = "Monday-Friday, 9am-5pm EST"

# Build the router
router = PatternRuby::Router.new do
  # --- Greetings ---
  intent :greeting do
    pattern "hello"
    pattern "hi"
    pattern "hey"
    pattern "good morning"
    pattern "good afternoon"
    pattern "good evening"
    pattern "hi there"
    pattern "hello there"
    pattern "hey there"
  end

  intent :farewell do
    pattern "bye"
    pattern "goodbye"
    pattern "see you"
    pattern "thanks bye"
    pattern "that's all"
  end

  # --- Order tracking ---
  intent :order_status do
    pattern "where is my order {order_id:\\d+}"
    pattern "track order {order_id:\\d+}"
    pattern "order status {order_id:\\d+}"
    pattern "check order {order_id:\\d+}"
    pattern(/order\s*#?\s*(?<order_id>\d{4,})/i)
    entity :order_id, type: :string
  end

  # --- Product / pricing ---
  intent :pricing do
    pattern "how much does {plan:basic|pro|enterprise} cost"
    pattern "price of {plan:basic|pro|enterprise}"
    pattern "pricing"
    pattern "plans"
    pattern "what plans do you have"
    entity :plan, type: :string
  end

  intent :compare_plans do
    pattern "compare plans"
    pattern "difference between plans"
    pattern "which plan should i (choose|pick|get)"
    pattern "compare {plan_a:basic|pro|enterprise} and {plan_b:basic|pro|enterprise}"
  end

  # --- Account ---
  intent :reset_password do
    pattern "reset [my] password"
    pattern "forgot [my] password"
    pattern "can't log in"
    pattern "change [my] password"
    pattern "locked out [of my account]"
  end

  intent :cancel_account do
    pattern "cancel [my] (account|subscription|plan)"
    pattern "i want to cancel"
    pattern "delete [my] account"
    pattern "unsubscribe"
  end

  # --- Refund ---
  intent :refund do
    pattern "i want [a] refund"
    pattern "refund [my] order {order_id:\\d+}"
    pattern "can i get [a] refund"
    pattern "money back"
    entity :order_id, type: :string
  end

  # --- Hours / contact ---
  intent :business_hours do
    pattern "what are your (hours|business hours)"
    pattern "when are you open"
    pattern "hours of operation"
    pattern "are you open (today|tomorrow|on weekends)"
  end

  intent :contact do
    pattern "how (can|do) i contact (you|support|a human)"
    pattern "talk to [a] (human|person|agent|representative)"
    pattern "phone number"
    pattern "email address"
    pattern "i need [to talk to] a human"
  end

  # --- Help ---
  intent :help do
    pattern "help"
    pattern "what can you do"
    pattern "what do you do"
    pattern "menu"
  end

  # --- Complaint ---
  intent :complaint do
    pattern "this is (terrible|awful|horrible|unacceptable)"
    pattern "i'm (unhappy|frustrated|angry|disappointed)"
    pattern "your (service|product|app) is (bad|broken|terrible)"
    pattern "i want to (complain|file a complaint)"
    pattern "not working"
  end

  fallback { |_| }
end

# Build preprocessing pipeline
pipeline = PatternRuby::Pipeline.new do
  step(:normalize) do |input|
    input.strip
      .gsub(/[.!?]+$/, "")      # strip trailing punctuation
      .gsub(/\s+/, " ")          # normalize whitespace
  end

  step(:correct) do |input|
    input
      .gsub(/\bpasword\b/i, "password")
      .gsub(/\baccout\b/i, "account")
      .gsub(/\bordrer\b/i, "order")
      .gsub(/\bprcing\b/i, "pricing")
      .gsub(/\bcansel\b/i, "cancel")
  end
end

# Response handler
def handle(result)
  case result.intent
  when :greeting
    "Hello! Welcome to Acme Support. How can I help you today?\n  Type 'help' to see what I can do."

  when :farewell
    "Thanks for contacting Acme Support! Have a great day. 👋"

  when :order_status
    oid = result.entities[:order_id]
    order = ORDERS[oid]
    if order
      msg = "Order ##{oid}: #{order[:item]}\n"
      msg += "  Status: #{order[:status].upcase}\n"
      msg += "  Ordered: #{order[:date]}\n"
      msg += "  Tracking: #{order[:tracking]}" if order[:tracking]
      msg
    else
      "I couldn't find order ##{oid}. Please check the order number and try again.\n  (Try: 10001, 10002, or 10003)"
    end

  when :pricing
    plan = result.entities[:plan]
    if plan
      info = PRODUCTS[plan]
      "#{plan.capitalize} Plan: #{info[:price]}\n  Features: #{info[:features]}"
    else
      PRODUCTS.map { |k, v| "  #{k.capitalize}: #{v[:price]} — #{v[:features]}" }.join("\n")
    end

  when :compare_plans
    PRODUCTS.map { |k, v| "  #{k.capitalize}: #{v[:price]} — #{v[:features]}" }.join("\n") +
      "\n  → Most popular: Pro plan"

  when :reset_password
    "To reset your password:\n  1. Go to acme.com/reset\n  2. Enter your email\n  3. Check your inbox for a reset link\n  Link expires in 1 hour."

  when :cancel_account
    "I'm sorry to hear that. To cancel:\n  1. Go to Settings → Billing\n  2. Click 'Cancel Plan'\n  Or reply with your reason and I'll connect you with our retention team."

  when :refund
    oid = result.entities[:order_id]
    if oid
      "I've submitted a refund request for order ##{oid}. You'll receive a confirmation email within 24 hours."
    else
      "I can help with a refund. Could you provide your order number?\n  (e.g., 'refund order 10001')"
    end

  when :business_hours
    "Our support hours are: #{HOURS}\n  For urgent issues outside hours, email urgent@acme.com"

  when :contact
    "You can reach us via:\n  Email: support@acme.com\n  Phone: 1-800-ACME-123\n  Live chat: acme.com/chat\n  Or I can connect you with a human agent now."

  when :help
    <<~HELP
      I can help with:
        • Order tracking — "track order 10001"
        • Pricing & plans — "pricing" or "compare plans"
        • Password reset — "reset password"
        • Refunds — "refund order 10001"
        • Business hours — "what are your hours"
        • Contact support — "talk to a human"
        • Cancel account — "cancel subscription"
    HELP

  when :complaint
    "I'm really sorry you're having a bad experience. Let me connect you with a senior support agent who can help resolve this right away.\n  [Escalating to human agent...]"

  else
    "I'm not sure I understand. Could you rephrase that?\n  Type 'help' to see what I can assist with."
  end
end

# --- Interactive REPL ---
puts "╔══════════════════════════════════════╗"
puts "║   Acme Support Bot (pattern-ruby)   ║"
puts "║   Type 'quit' to exit               ║"
puts "╚══════════════════════════════════════╝"
puts

convo = PatternRuby::Conversation.new(router)

loop do
  print "You: "
  input = $stdin.gets
  break unless input
  input = input.strip
  break if input.downcase == "quit" || input.downcase == "exit"
  next if input.empty?

  # Preprocess then match
  cleaned = pipeline.process(input)
  result = convo.process(cleaned)

  response = handle(result)
  puts "Bot: #{response}"
  puts

  break if result.intent == :farewell
end
