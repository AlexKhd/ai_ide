module ApplicationHelper

  def message_class(message)
    return 'text-blue-800 text-right text-sm' if message.role == 'user'
    return 'text-gray-600 text-center text-sm' if message.role == 'tool'
    return 'text-gray-800' # default
  end

  def ai_delete_button_svg
    '<svg fill="gray" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">  <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>  <path d="M0 0h24v24H0z" fill="none"/></svg>'.html_safe
  end

  def td_long_text(comment, cut_length)
    cut_length.present? ? cl = cut_length : cl = 10 # default value
    if comment
      if comment.to_s.length > cl+3
        concat(content_tag(:td, comment.to_s, data: {controller: "tooltips",
         bs_toggle: "tooltip", bs_title: comment, bs_placement: "top"}) do
          concat(comment.truncate(cl+3))
        end)
        return
      else
        concat(content_tag(:td, comment.to_s) do
          concat(comment)
        end)
        return
      end
    else
      #return
    end
  end
end
