defmodule Events.Ews do

  def get_calendar_events(endpoint, user, password) do
    credentials = {endpoint, user, password}
    get_folder(:calendar, credentials)
      |> find_item_ids(credentials)
      |> get_items(credentials)
  end

  # PRIVATE API

  defp get_folder(folder_id, {endpoint, user, password}) do
    encoded_credentials = Base.encode64("#{user}:#{password}")
    req_body = get_folder_request(folder_id)
    req_headers = %{"Authorization" => "Basic #{encoded_credentials}", "Content-Type" => "text/xml"}
    case HTTPoison.post(endpoint, req_body, req_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with doc = Exml.parse(body),
             id = Exml.get(doc, "//t:CalendarFolder/t:FolderId/@Id") do
          {:ok, {id}}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp find_item_ids({:ok, {id}} = _folder, {endpoint, user, password}) do
    encoded_credentials = Base.encode64("#{user}:#{password}")
    req_body = find_item_request({id})
    req_headers = %{"Authorization" => "Basic #{encoded_credentials}", "Content-Type" => "text/xml"}
    case HTTPoison.post(endpoint, req_body, req_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with doc = Exml.parse(body) do
          {:ok, Exml.get(doc, "//t:CalendarItem/t:ItemId/@Id")}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp get_items({:ok, item_ids}, {endpoint, user, password}) do
    encoded_credentials = Base.encode64("#{user}:#{password}")
    req_body = get_item_request(item_ids)
    req_headers = %{"Authorization" => "Basic #{encoded_credentials}", "Content-Type" => "text/xml"}
    case HTTPoison.post(endpoint, req_body, req_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with doc = Exml.parse(body) do
          items = for id <- item_ids, into: [] do
            item_selector = "//m:GetItemResponseMessage/m:Items/t:CalendarItem[t:ItemId/@Id='#{id}']"
            %{"id" => id,
              "subject" => Exml.get(doc, item_selector <> "/t:Subject"),
              "start" => Exml.get(doc, item_selector <> "/t:Start"),
              "end" => Exml.get(doc, item_selector <> "/t:End"),
              "time_zone" => Exml.get(doc, item_selector <> "/t:TimeZone"),
              "all_day" => Exml.get(doc, item_selector <> "/t:IsAllDayEvent"),
              "cancelled" => Exml.get(doc, item_selector <> "/t:IsCancelled"),
              "recurring" => Exml.get(doc, item_selector <> "/t:IsRecurring"),
              "my_response_type" => Exml.get(doc, item_selector <> "/t:MyResponseType"),
              "location" => Exml.get(doc, item_selector <> "/t:Location"),
              "organizer" => Exml.get(doc, item_selector <> "/t:Organizer/t:Mailbox/t:EmailAddress")}
          end
          {:ok, items}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end

  end

  defp get_folder_request(folder_id) do
    """
    <?xml version="1.0"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages">
        <soap:Header>
            <t:RequestServerVersion Version="Exchange2010"/>
        </soap:Header>
        <soap:Body>
            <GetFolder xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
                <FolderShape>
                    <t:BaseShape>Default</t:BaseShape>
                </FolderShape>
                <m:FolderIds>
                    <t:DistinguishedFolderId Id="#{folder_id}"/>
                </m:FolderIds>
            </GetFolder>
        </soap:Body>
    </soap:Envelope>
    """
  end

  defp find_item_request({id} = _folder) do
    """
    <?xml version="1.0"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages">
        <soap:Header>
            <t:RequestServerVersion Version="Exchange2010"/>
        </soap:Header>
        <soap:Body>
            <FindItem xmlns="http://schemas.microsoft.com/exchange/services/2006/messages" Traversal="Shallow">
                <ItemShape>
                    <t:BaseShape>Default</t:BaseShape>
                </ItemShape>
                <m:ParentFolderIds>
                    <t:FolderId Id="#{id}"/>
                </m:ParentFolderIds>
            </FindItem>
        </soap:Body>
    </soap:Envelope>
    """
  end

  def get_item_request(item_ids) do
    """
    <?xml version="1.0"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages">
        <soap:Header>
            <t:RequestServerVersion Version="Exchange2010"/>
        </soap:Header>
        <soap:Body>
            <GetItem xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
                <ItemShape>
                    <t:BaseShape>AllProperties</t:BaseShape>
                </ItemShape>
                <ItemIds>
                    #{Enum.map(item_ids, fn id -> ~s(<t:ItemId Id="#{id}" />) end)}
                </ItemIds>
            </GetItem>
        </soap:Body>
    </soap:Envelope>
    """
  end

end