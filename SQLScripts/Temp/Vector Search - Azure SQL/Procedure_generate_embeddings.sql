-- This script creates a stored procedure wrapper to invoke the generation of embeddings using Azure OpenAI Service.

CREATE PROCEDURE dbo.generate_embedding
	@inputText NVARCHAR(MAX),
    @responseVector VECTOR(1536) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

	declare @retval int, @response nvarchar(max);
	declare @payload nvarchar(max) = json_object('input': @inputText);
	exec @retval = sp_invoke_external_rest_endpoint
		@url = 'https://your-custom-endpoint.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-05-15',
		@method = 'POST',
		@headers = '{"api-key":"YOURKEYGOESHERE"}',
		@payload = @payload,
		@response = @response output;
	-- select @response;
	set @responseVector = json_query(@response, '$.result.data[0].embedding')
	-- select @responseVector;
END;

-- Testing the procedure
DECLARE @output VECTOR(1536);
EXEC dbo.generate_embedding @inputText = 'Azure SQL AI day!', @responseVector = @output OUTPUT;
SELECT @output AS OpenAIResponse;