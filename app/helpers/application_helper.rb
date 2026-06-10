module ApplicationHelper
  def markdown(text)
    return "".html_safe if text.blank?
    html = Commonmarker.to_html(text.to_s)
    sanitize(html, tags: %w[p strong em b i ul ol li h1 h2 h3 h4 h5 h6 blockquote code pre br a], attributes: %w[href])
  end
end
