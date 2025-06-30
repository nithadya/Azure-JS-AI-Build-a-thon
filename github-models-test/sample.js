import ModelClient, { isUnexpected } from "@azure-rest/ai-inference";
import { AzureKeyCredential } from "@azure/core-auth";
import * as fs from "fs";

const token = process.env["GITHUB_TOKEN"];
const endpoint = "https://models.github.ai/inference";
const modelName = "meta/Llama-4-Maverick-17B-128E-Instruct-FP8";

export async function main() {
  const client = ModelClient(endpoint, new AzureKeyCredential(token));

  // Read and encode the image as base64
  const imageBuffer = fs.readFileSync("contoso_layout_sketch.jpg");
  const base64Image = imageBuffer.toString("base64");

  const response = await client.path("/chat/completions").post({
    body: {
      messages: [
        { role: "system", content: "You are a helpful assistant." },
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "write HTML and CSS code for a web page based on the following hand-drawn sketch",
            },
            {
              type: "image_url",
              image_url: `data:image/jpeg;base64,${base64Image}`,
            },
          ],
        },
      ],
      model: modelName,
      max_tokens: 1000, // Reduce max_tokens to avoid exceeding token limit
    },
  });

  if (isUnexpected(response)) {
    throw response.body.error;
  }

  console.log(response.body.choices[0].message.content);
}

main().catch((err) => {
  console.error("The sample encountered an error:", err);
});
