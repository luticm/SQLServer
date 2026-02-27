

ALTER PROCEDURE dbo.generate_embedding
	@inputText NVARCHAR(MAX),
    @responseVector VECTOR(1536) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
--declare @responseVector VECTOR(1536)
--declare @inputText nvarchar(max) = 'the foundation series by isaac asimov';
	declare @retval int, @response nvarchar(max);
	declare @payload nvarchar(max) = json_object('input': @inputText);
	exec @retval = sp_invoke_external_rest_endpoint
		@url = 'https://cosmicgbb-openai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-05-15',
		@method = 'POST',
		@headers = '{"api-key":"YOURKEYGOESHERE"}',
		@payload = @payload,
		@response = @response output;
	-- select @response;
	set @responseVector = json_query(@response, '$.result.data[0].embedding')
	-- select @responseVector;
END;



SELECT COUNT(*)
FROM ai.netflix_titles AS NT WITH (NOLOCK)
WHERE document_vector IS NOT NULL;


DECLARE @output VECTOR(1536);
EXEC dbo.generate_embedding @inputText = 'What is the capital of Brazil?', @responseVector = @output OUTPUT;
SELECT @output AS OpenAIResponse;


DECLARE @e vector(1536);
EXEC dbo.generate_embedding 'Sports movie that shows the struggle of a team to win the championship', @e OUTPUT;

SELECT TOP 3 *
FROM ai.netflix_titles AS NT
ORDER BY vector_distance('cosine', NT.document_vector, @e)