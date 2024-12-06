import React from 'react'
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import {
  Credenza,
  CredenzaBody,
  CredenzaClose,
  CredenzaContent,
  CredenzaDescription,
  CredenzaHeader,
  CredenzaTitle,
} from "@/components/credeza"
import { Plus } from 'lucide-react'

const formSchema = z.object({
  blockName: z.string().min(1, "Block name is required"),
  solidityCode: z.string().min(1, "Solidity code is required"),
})

interface CustomBlockModalProps {
  isOpen: boolean
  onOpenChange: (open: boolean) => void
  onSubmitCustomBlock: (values: z.infer<typeof formSchema>) => void
}

export default function CustomBlock({ isOpen, onOpenChange, onSubmitCustomBlock }: CustomBlockModalProps) {
  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      blockName: "",
      solidityCode: "",
    },
  })

  return (
    <>
      <div className="pb-12 p-6 w-72 -mt-6">
        <Button
          onClick={() => onOpenChange(true)}
          className="bg-white hover:bg-whte hoverEffect text-black w-full"
        >
          <Plus className="w-4 h-4 mr-2" />
          Add Custom Block
        </Button>
      </div>
      <Credenza open={isOpen} onOpenChange={onOpenChange}>
        <CredenzaContent className="border-white/10">
          <CredenzaHeader>
            <CredenzaTitle className="text-white">Add a Custom Block</CredenzaTitle>
            <CredenzaDescription className="text-white/80">
              Enter your Solidity code below to create a custom block.
            </CredenzaDescription>
          </CredenzaHeader>
          <CredenzaBody>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmitCustomBlock)} className="space-y-4">
                <FormField
                  control={form.control}
                  name="blockName"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-white">Block Name</FormLabel>
                      <FormControl>
                        <input
                          {...field}
                          className="w-full p-2 rounded bg-[#1F1F1F] text-white border border-[#2A2A2A] focus:border-[#4A4A4A]"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="solidityCode"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-white">Solidity Code</FormLabel>
                      <FormControl>
                        <Textarea
                          {...field}
                          placeholder="Enter your Solidity code here..."
                          className="font-mono h-40 bg-[#1F1F1F] text-white border-[#2A2A2A] focus:border-[#4A4A4A]"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <div className="flex justify-end space-x-2">
                  <CredenzaClose asChild>
                    <Button variant="secondary" type="button">
                      Cancel
                    </Button>
                  </CredenzaClose>
                  <Button type="submit">Create Block</Button>
                </div>
              </form>
            </Form>
          </CredenzaBody>
        </CredenzaContent>
      </Credenza>
    </>
  )
}
