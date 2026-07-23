vim.filetype.add({
  pattern = {
    ['docker%-compose%.yml'] = 'yaml.docker-compose',
    ['compose%.yaml'] = 'yaml.docker-compose',
  },
})
