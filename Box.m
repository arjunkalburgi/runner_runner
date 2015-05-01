classdef Box
    properties
        xpos = 0;
        ypos = 0;
        xlength = 0;
        ylength = 0;
        velocity = [0 0]; %velocity in x and y components
        image;
        image_map;
        type = 0; %0 = hero, 1 = straight box; 2 = sin function
    end
    methods
        %construct & set initial values
        function obj = Box(xpos,ypos,xlength,ylength,velocity,image,type)
            %set object's variables to those supplied
            obj.xpos = xpos;
            obj.ypos = ypos;
            obj.xlength =xlength;
            obj.ylength = ylength;
            obj.velocity = velocity;
            obj.image = image;
            obj.type = type;
        end
        %move boxs according to their velocity and movement type
        function[obj] = move(obj,delta_time)
            global GMSTATE
            switch obj.type
                
                case 0 %hero movement
                    %gravity
                    obj.velocity(2) = obj.velocity(2)-75*delta_time;
                    %hit ground?
                    if obj.ypos <= 5
                        obj.ypos = 5; %move to ground level
                        obj.velocity(2) = 0;%stop moving
                        obj.velocity(2) = obj.velocity(2)-obj.velocity(2); %stop moving down
                    end
                    %jump if you haven't hit the ceiling
                    if obj.ypos+obj.ylength>100
                        obj.velocity(2) = 0;
                        obj.ypos = 100-obj.ylength;
                    elseif strcmp(GMSTATE.key,'space') &&(obj.ypos+obj.ylength)<95
                        obj.velocity(2) = obj.velocity(2)+150*delta_time;
                    end
                    
                case 1 %straight movement
                    % Make sure they don't go out of bounds.
                    if obj.ypos < 0
                        obj.velocity(2) = obj.velocity(2)*-1;
                        obj.ypos = 0;
                    elseif obj.ypos+obj.ylength > 100
                        obj.velocity(2) = obj.velocity(2)*-1;
                        obj.ypos = 100-obj.ylength;
                    end
                    
                case 2 % switch velocities
                    if obj.xpos >35 && mod(floor(obj.xpos),15)==0
                        obj.velocity(2) = obj.velocity(2)*-(0.9+0.2*rand());
                    end
                    % Make sure they don't go out of bounds.
                    if obj.ypos < 0
                        obj.velocity(2) = obj.velocity(2)*-1;
                        obj.ypos = 0;
                    elseif obj.ypos+obj.ylength > 100
                        obj.velocity(2) = obj.velocity(2)*-1;
                        obj.ypos = 100-obj.ylength;
                    end
                    
            end
            %move object according to previous stuff
            obj.xpos = obj.xpos+obj.velocity(1)*delta_time;
            obj.ypos = obj.ypos+obj.velocity(2)*delta_time;
        end
    end
end