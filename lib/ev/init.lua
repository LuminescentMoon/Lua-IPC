return function(currentDir, ...)
  currentDir = currentDir or '.'
  return require(currentDir .. '.src.Main')(currentDir, ...)
end
