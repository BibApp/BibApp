module PublishersHelper
  def can_use_pdf_str(publisher)
    publisher.archive_publisher_copy? ? "Yes" : "No"
  end
end
