// /GitHubConnector.ts
export class GitHubConnector {
  private token: string;
  constructor(token: string) {
    this.token = token;
  }
  async saveGist(filename: string, content: string): Promise<string> {
    const response = await fetch("https://api.github.com/gists", {
      method: "POST",
      headers: { Authorization: `token ${this.token}` },
      body: JSON.stringify({
        files: { [filename]: { content } },
        public: false,
      }),
    });
    const data = await response.json();
    return data.html_url;
  }
}