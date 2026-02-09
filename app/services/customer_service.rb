module CustomerService
  class Unavailable < StandardError; end
  class NotFound < StandardError; end
  class BadResponse < StandardError; end
end
