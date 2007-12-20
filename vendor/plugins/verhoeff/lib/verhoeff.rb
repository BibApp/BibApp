# Verhoeff
module ActiveSupport
  module CoreExtensions
    module Integer
      module VerhoeffChecksum
        
        def to_verhoeff
        	c = 0
        	n = self.to_s.reverse

        	for i in 0...n.length
        		c = d(c, p(i+1, n[i,1].to_i))
          end
        	return (self.to_s+inv(c).to_s).to_i
        end
        
        def is_verhoeff?
        	c = 0
        	n = self.to_s.reverse

        	for i in 0...n.length
        		c = d(c, p(i, n[i,1].to_i))
          end
        	return c == 0
          
        end
        
        def from_verhoeff
          return nil if !self.is_verhoeff?
          self.to_s.chop.to_i
        end
        
        private
        def d(j, k)
        	table = [
        		[0,1,2,3,4,5,6,7,8,9],
        		[1,2,3,4,0,6,7,8,9,5],
        		[2,3,4,0,1,7,8,9,5,6],
        		[3,4,0,1,2,8,9,5,6,7],
        		[4,0,1,2,3,9,5,6,7,8],
        		[5,9,8,7,6,0,4,3,2,1],
        		[6,5,9,8,7,1,0,4,3,2],
        		[7,6,5,9,8,2,1,0,4,3],
        		[8,7,6,5,9,3,2,1,0,4],
        		[9,8,7,6,5,4,3,2,1,0]
        	]
          
        	return table[j][k]
        end
        
        def p(pos, num)
        	table = [
        		[0,1,2,3,4,5,6,7,8,9],
        		[1,5,7,6,2,8,3,0,9,4],
        		[5,8,0,3,7,9,6,1,4,2],
        		[8,9,1,6,0,4,3,5,2,7],
        		[9,4,5,3,1,2,6,8,7,0],
        		[4,2,8,6,5,7,3,9,0,1],
        		[2,7,9,3,8,0,6,4,1,5],
        		[7,0,4,6,9,1,3,2,5,8]
      		]

        	return table[pos % 8][num]
      	end
      	
      	def inv(j)
        	table = [0,4,3,2,1,5,6,7,8,9]
        	return table[j]
        end
        
      end
    end
  end
end

class Integer
  include ActiveSupport::CoreExtensions::Integer::VerhoeffChecksum
end