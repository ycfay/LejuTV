const listEl = document.querySelector("#channel-list");
const countEl = document.querySelector("#channel-count");
const toastEl = document.querySelector("#toast");
const restoreButton = document.querySelector("#restore-button");
const clearButton = document.querySelector("#clear-button");

async function api(path, options) {
    const response = await fetch(path, options);
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`);
    return data;
}

function toast(message) {
    toastEl.textContent = message;
}

async function loadChannels() {
    const data = await api("/api/channels");
    const channels = data.channels ?? [];
    countEl.textContent = `${channels.length} 个`;
    clearButton.disabled = channels.length === 0;
    listEl.innerHTML = "";
    channels.forEach((channel) => {
        const row = document.createElement("div");
        row.className = "channel-row";
        row.innerHTML = `<div><strong></strong><small></small></div><button class="delete-button" type="button">删除</button>`;
        row.querySelector("strong").textContent = channel.name;
        row.querySelector("small").textContent = channel.url;
        row.querySelector("button").onclick = async () => {
            await api("/api/delete", {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({url: channel.url})});
            toast("已删除");
            await loadChannels();
        };
        listEl.appendChild(row);
    });
}

clearButton.onclick = async () => {
    if (!window.confirm("确定删除全部频道吗？")) return;
    const result = await api("/api/clear", {method: "POST"});
    toast(result.deleted > 0 ? `已删除 ${result.deleted} 个频道` : "当前没有可删除的频道");
    await loadChannels();
};

restoreButton.onclick = async () => {
    if (!window.confirm("将用内置默认频道替换当前列表，确定继续吗？")) return;
    const result = await api("/api/defaults", {method: "POST"});
    toast(result.restored > 0 ? `已恢复 ${result.restored} 个默认频道` : "默认频道不可用");
    await loadChannels();
};

loadChannels().catch(() => toast("加载失败，请确认电视端管理窗口仍然打开"));
