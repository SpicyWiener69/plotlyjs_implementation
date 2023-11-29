
using Plots
#hellof
#forkedbyicy
#define global constants, read only
p_inf = 0.4
p_sev = 0.2
p_rec = 1-p_sev
p_recSI = 0.6
p_recur = 0.1

Lookup_table = [1-p_inf p_inf   0         0;
                0       0       p_sev     p_rec;
                0       0       1-p_recSI p_recSI;
                p_recur 0       0         1-p_recur]


states = ["sus" "inf" "sev" "rec"]

function GetIndex(current_state)
    len = length(states)
    for i in 1:len
        if states[i] == current_state
            return i
        end
    end
    return 0
end

function SwitchState(Probabilities)
    random = rand(Float64)
    probability_sum = 0
    for (index,probability) in enumerate(Probabilities) #switch to state based on random Float64
        probability_sum += probability
        if random < probability_sum
            return states[index]
        end
    end
    return 0
end

function RunFsmOnce(current_state)
    index = GetIndex(current_state)
    Probablilites = Lookup_table[index,:] #slice lookup_table
    return SwitchState(Probablilites)
end

function CreateSeedArray(width,height,seed_count)
    size = width*height
    vect = [ "" for a in 1:size]
    random = unique(rand(1:size, seed_count))
    for i in random
        vect[i] ="inf"
    end
    return reshape(vect,height,width)  #reshape arr to desired dim
    
end

function MarkSuspected(arr)
    height = size(arr)[1]
    width = size(arr)[2]
    infect_pos = findall(x -> x == "sev" || x == "inf", arr) #findall with probability of infecting others
    sus_grids = []
    for coordinates in infect_pos
        append!(sus_grids, availableGrids(coordinates, width, height))
    end
    for sus_grid in sus_grids
        if !(arr[sus_grid[1],sus_grid[2]] in states)
            arr[sus_grid[1],sus_grid[2]] = "sus"   
        end
    end
end

function availableGrids(coordinates, width, height)
    x = coordinates[1]
    y = coordinates[2]
    box =  [(x-1,y-1), (x-1,y), (x-1,y+1),
            (x,y-1),            (x,y+1),
            (x+1,y-1), (x+1,y), (x+1,y+1)]
    filtered_box = []
    
    for point in box
        if (point[1] in 1:height) && (point[2] in 1:width) #insure grid in range of arr
            push!(filtered_box, point)                     
        end
    end
    return filtered_box 
end

function Draw(arr,sev_vector)
    num_arr = replace(arr, "" => 0,"rec"=> 1, "sus" => 2, "inf" =>3, "sev" => 4)#map states=>values 
    p1 = heatmap(num_arr, yflip = true, c=cgrad([:white, :green, :blue, :red]))
    
    sev_count =count(i->(i=="sev"),arr)
    push!(sev_vector,sev_count)
    p2 = plot(sev_vector)
    display(plot(p1,p2,layout=(2, 1), legend=false))

end

function main()
    #test parameters
    width = 20
    height = 20
    seed_count = 3
    generation_count = 5
    sleep_interval = 0.1
    
    arr = CreateSeedArray(width,height,seed_count)#2D matrix of test object
    sev_vector = [] #list with count of "sev" cases

    for i in 1:generation_count   
        Draw(arr,sev_vector)
        MarkSuspected(arr)
        for (index,person) in enumerate(arr)
            if person in states
                current_state = person 
                arr[index] = RunFsmOnce(current_state)  
            end
        end
        sleep(sleep_interval)
    end
end

main()
