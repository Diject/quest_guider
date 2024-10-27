local gradient = {}

for r = 0.1, 1, 0.1 do
    for g = 0.1, 1, 0.1 do
        for b = 0.1, 1, 0.1 do
            if (not math.isclose(r, g, 0.3) or not math.isclose(g, b, 0.3) or not math.isclose(r, b, 0.3)) and r + g + b > 1.8 then
                table.insert(gradient, {r, g, b})
            end
        end
    end
end

return gradient