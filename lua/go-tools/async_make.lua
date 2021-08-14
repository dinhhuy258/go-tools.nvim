local M = {}

function M.make(...)
  local args = { ... }
  local lines = { "" }
  local winnr = vim.fn.win_getid()
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local makeprg = vim.api.nvim_buf_get_option(bufnr, "makeprg")
  if not makeprg then
    return
  end

  vim.cmd [[setl errorformat =%-G#\ %.%#]]
  if makeprg:find "go build" then
    vim.cmd [[setl errorformat+=%-G%.%#panic:\ %m]]
    vim.cmd [[setl errorformat+=%Ecan\'t\ load\ package:\ %m]]
    vim.cmd [[setl errorformat+=%A%\\%%(%[%^:]%\\+:\ %\\)%\\?%f:%l:%c:\ %m]]
    vim.cmd [[setl errorformat+=%A%\\%%(%[%^:]%\\+:\ %\\)%\\?%f:%l:\ %m]]
    vim.cmd [[setl errorformat+=%C%*\\s%m]]
    vim.cmd [[setl errorformat+=%-G%.%#]]
  end
  if makeprg:find "golangci-lint" then
    -- lint
    vim.cmd [[setl errorformat+=%-G#\ %.%#,%f:%l:%c:\\?\ %m]]
  end
  if makeprg == "go run" and #args == 0 then
    vim.cmd [[setl makeprg=go\ run\ \.]]
    makeprg = makeprg .. " ."
    vim.api.nvim_buf_set_option(bufnr, "makeprg", makeprg)
  end

  local arg = " "
  for _, v in pairs(args or {}) do
    arg = arg .. " " .. v
  end

  if #arg then
    makeprg = makeprg .. arg

    vim.api.nvim_buf_set_option(bufnr, "makeprg", makeprg)
  end
  local cmd = vim.fn.expandcmd(makeprg)

  local function on_event(_, data, event)
    if event == "stdout" or event == "stderr" then
      if data then
        vim.list_extend(lines, data)
      end
    end

    if event == "exit" then
      vim.fn.setqflist({}, " ", {
        title = cmd,
        lines = lines,
        efm = vim.api.nvim_buf_get_option(bufnr, "errorformat"),
      })
      vim.api.nvim_command "doautocmd QuickFixCmdPost"
    end
    if #lines > 1 then
      vim.cmd "copen"
    end
  end

  vim.fn.jobstart(cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
