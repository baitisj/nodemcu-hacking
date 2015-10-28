local M
do
  local q = {}
  local size=10
  local head=1
  local tail=1
  local cnt=0

  function push(x)
    if cnt == size then
      return nil
    end
    q[head] = x
    head = head % size + 1
    cnt=cnt+1
    return cnt
  end

  function pop()
    if cnt == 0 then
      return nil
    end
    data=q[tail]
    q[tail] = nil
    tail = tail % size + 1
    cnt=cnt-1
    return data
  end

  function setSize(x)
    if cnt ~= 0 then return nil
    else size=x
    end
  end

  M = {
    push = push,
    pop = pop,
    setSize = setSize
  }
end
return M
