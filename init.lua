return function(currentDir, ...)
  return require(currentDir .. '.src.Main')(currentDir, ...)
end
