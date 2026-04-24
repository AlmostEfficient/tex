# Gemini 1.5 Flash Pricing Calculator
cost_per_1m_input_tokens = 0.075
cost_per_1m_output_tokens = 0.30

# Image token cost for Gemini 1.5
tokens_per_image = 258

# Estimated output tokens (translating a typical screenshot)
# Assume ~100 words of English output per image
output_tokens_per_image = 150

images = 1000

input_cost = (images * tokens_per_image / 1_000_000) * cost_per_1m_input_tokens
output_cost = (images * output_tokens_per_image / 1_000_000) * cost_per_1m_output_tokens
total_cost = input_cost + output_cost

print(f"Cost for 1000 images:")
print(f"Input cost ({images * tokens_per_image} tokens): ${input_cost:.4f}")
print(f"Output cost ({images * output_tokens_per_image} tokens): ${output_cost:.4f}")
print(f"Total cost: ${total_cost:.4f}")
